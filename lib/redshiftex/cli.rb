require "thor"
require 'open-uri'
require 'erb'
require 'active_record'
require 'json'

module Redshiftex
  class CLI < Thor
    register(Ridgepole, 'ridgepole', 'ridgepole [COMMAND]', 'subcommad for ridgepole')
    class_option :config, aliases: '-c',type: :string, desc: 'database.yml'
    class_option :environment, aliases: '-E', type: :string, default: nil, desc: 'environment'
    class_option :schemafile, type: :string, default: 'Schemafile', desc: 'schemafile'
    class_option :dryrun, type: :boolean, default: false, desc: 'dryrun'
    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @class_options = config[:shell].base.options
      @core = Core.new
      @yaml = @core.connection(@class_options[:config], @class_options[:environment])
      @logger = @core.logger
      ActiveRecord::Base.establish_connection(@yaml)
    end

    desc 'copy', 'copy'
    option :copy_option, type: :string, required: true, desc: 'copy option'
    option :path, type: :string, required: true, desc: 'path'
    option :tables, type: :array, required: true, desc: 'tables'
    def copy
      options[:tables].each do |table|
        copy_proc(options[:path], options[:copy_option], table)
      end
    end

    desc 'copy_all', 'copy_all'
    option :copy_option, type: :string, required: true, desc: 'copy option'
    option :path, type: :string, required: true, desc: 'path'
    option :excludes, type: :array, default: [],desc: 'excludes tables. can use regexp.'
    def copy_all
      tables = ActiveRecord::Base.connection.tables
      regexps = options[:excludes].map{ |exclude| Regexp.new(exclude) }
      excludes = get_excludes(tables, regexps)
      @logger.info("exlude tables => #{excludes.join(',')}") unless excludes.empty?
      tables = tables - excludes
      tables.each do |table|
        copy_proc(options[:path], options[:copy_option], table)
      end
    end

    private
    def get_excludes(tables, regexps)
      tables.select do |table|
        compare(table, regexps)
      end
    end

    def compare(table, regexps)
      regexps.each do |regexp|
        return true if regexp.match(table)
      end
      return false
    end

    def copy_proc(path, copy_option, table)
      @credential = @core.credential
      @table = table
      @path = ERB.new(path).result(binding)
      @copy_option = copy_option
      template_path = File.expand_path('../../../template/copy.sql.erb', __FILE__)
      sql = ERB.new(File.read(template_path)).result(binding)

      # credentialの情報を確認したい場合は@credentialで確認できる
      @logger.info "COPY #{@table}"
      @logger.info "FROM #{@path}"
      @logger.info "COPY_OPTION #{@copy_option}"
      begin
        ActiveRecord::Base.connection.execute(sql) unless @class_options[:dryrun]
      rescue Exception => e
        if e.message =~ /The specified S3 prefix .* does not exist/
          @logger.warn("s3 object not exist => #{@path}")
        else
          @logger.error("\n#{e.message}\n#{e.backtrace.join("\n")}")
          raise
        end
      end
    end
  end
end
