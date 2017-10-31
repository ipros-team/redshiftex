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
    option :excludes, type: :array, default: [],desc: 'excludes'
    def copy_all
      tables = ActiveRecord::Base.connection.tables
      tables = tables - options[:excludes]
      tables.each do |table|
        copy_proc(options[:path], options[:copy_option], table)
      end
    end

    private

    def copy_proc(path, copy_option, table)
      @credential = @core.credential
      @table = table
      @path = ERB.new(path).result(binding)
      @copy_option = copy_option
      template_path = File.expand_path('../../../template/copy.sql.erb', __FILE__)
      sql = ERB.new(File.read(template_path)).result(binding)
      @logger.info(sql)
      begin
        ActiveRecord::Base.connection.execute(sql) unless @class_options[:dryrun]
      rescue Exception => e
        @logger.error("\n#{e.message}\n#{e.backtrace.join("\n")}")
      end
    end
  end
end
