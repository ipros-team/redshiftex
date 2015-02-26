require "thor"

module Redshiftex
  class CLI < Thor

    map '--version' => :version

    #class_option :rails, aliases: '--rails', type: :boolean, required: true, desc: 'header'
    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @global_options = config[:shell].base.options
      @core = Core.new
    end

    desc 'sample', 'Sample task'
    def sample
      puts "This is your new task"
    end

    desc 'version', 'show version'
    def version
      puts VERSION
    end

  end
end
