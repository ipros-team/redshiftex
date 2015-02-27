require "thor"
require 'open-uri'
require 'erb'
require 'active_record'
require 'json'

module Redshiftex
  class CLI < Thor
    register(Ridgepole, 'ridgepole', 'ridgepole [COMMAND]', 'subcommad for ridgepole')
    class_option :config, aliases: '-c',type: :string, desc: 'default is first data'
    class_option :environment, aliases: '-E', type: :string, default: nil, desc: 'default is first data'
    class_option :schemafile, type: :string, default: 'Schemafile', desc: 'default is first data'
    class_option :dryrun, type: :boolean, default: false, desc: 'default is first data'
    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @class_options = config[:shell].base.options
      @core = Core.new
      @yaml = @core.connection(@class_options['config'], @class_options['environment'])
      @logger = @core.logger
    end

    desc 'copy', 'copy'
    option :copy_option, type: :string, required: true, desc: 'header'
    option :path, type: :string, required: true, desc: 'header'
    option :table, type: :string, required: true, desc: 'header'
    def copy
      @credential = get_credential
      @path = options['path']
      @copy_option = options['copy_option']
      @table = options['table']
      template_path = File.expand_path('../../../template/copy.sql.erb', __FILE__)
      ActiveRecord::Base.establish_connection(@yaml)
      sql = ERB.new(File.read(template_path)).result(binding)
      @logger.info(sql)
      begin
        ActiveRecord::Base.connection.execute(sql) unless @class_options['dryrun']
      rescue Exception => e
        @logger.error("\n#{e.message}\n#{e.backtrace.join("\n")}")
      end
    end

    private

    def get_credential
      credentials = {}
      iam_role = get_iam_metadata
      if iam_role.empty?
        credentials['aws_access_key_id'] = ENV['AWS_ACCESS_KEY_ID']
        credentials['aws_secret_access_key'] = ENV['AWS_SECRET_ACCESS_KEY']
      else
        credentials['aws_access_key_id'] = iam_role['AccessKeyId']
        credentials['aws_secret_access_key'] = iam_role['SecretAccessKey']
        credentials['token'] = iam_role['Token']
      end
      credentials.map{ |k, v| "#{k}=#{v}" }.join(';')
    end

    def get_iam_metadata
      begin
        result = {}
        timeout(10) {
          role = open('http://169.254.169.254/latest/meta-data/iam/security-credentials/').read
          body = open('http://169.254.169.254/latest/meta-data/iam/security-credentials/' + role).read
          return JSON.parse(body)
        }
      rescue TimeoutError => e
      rescue Exception => e
      end
      return result
    end
  end
end
