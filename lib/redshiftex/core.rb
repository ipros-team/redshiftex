require 'yaml'
require 'logger'

module Redshiftex
  class Core

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
  end
end
