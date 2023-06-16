require 'yaml'
require 'logger'
require 'timeout' unless defined?(Timeout)
require 'uri'

module Redshiftex
  class Core

    SECURITY_CREDENTIALS_URL = "http://169.254.170.2#{ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI']}"

    def initialize
    end

    def connection(path, environment)
      @yaml = YAML.load(ERB.new(File.read(path)).result)
      @yaml = @yaml[environment] if environment
      @yaml
    end

    def logger
      ::Logger.new($stdout)
    end

    def credential
      credentials = {}
      if ENV['AWS_ACCESS_KEY_ID']
        credentials['aws_access_key_id'] = ENV['AWS_ACCESS_KEY_ID']
        credentials['aws_secret_access_key'] = ENV['AWS_SECRET_ACCESS_KEY']
      else
        iam_role = iam_metadata
        credentials['aws_access_key_id'] = iam_role['AccessKeyId']
        credentials['aws_secret_access_key'] = iam_role['SecretAccessKey']
        credentials['token'] = iam_role['Token']
      end
      credentials.map{ |k, v| "#{k}=#{v}" }.join(';')
    end

    def iam_metadata
      begin
        result = {}
        Timeout.timeout(10) {
          body = URI.open(SECURITY_CREDENTIALS_URL).read
          return JSON.parse(body)
        }
      rescue Timeout::Error => e
      rescue Exception => e
      end
      return result
    end
  end
end
