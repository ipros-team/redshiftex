require "thor"
require 'yaml'
require 'active_record'

module Redshiftex
  class Ridgepole < Thor

    class_option :config, aliases: '-c',type: :string, desc: 'default is first data'
    class_option :environment, aliases: '-E', type: :string, default: nil, desc: 'default is first data'
    class_option :schemafile, type: :string, default: 'Schemafile', desc: 'default is first data'
    class_option :dryrun, type: :boolean, default: false, desc: 'default is first data'
    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @class_options = config[:shell].base.options
      @core = Core.new
      @cmd = "bundle exec ridgepole --diff #{@class_options['config']} #{@class_options['schemafile']}"
      @cmd = @cmd + " -E #{@class_options['environment']}" if @class_options['environment']
      @yaml = @core.connection(@class_options['config'], @class_options['environment'])
      @logger = @core.logger
    end

    desc "apply", "apply"
    def apply
      ridgepole_diff(false)
    end

    desc "diff", "diff"
    def diff
      ridgepole_diff(true)
    end

    private

    def ridgepole_diff(dryrun)
      diff = cleansing(`#{@cmd}`)
      ActiveRecord::Base.establish_connection(@yaml)
      diff.each do |sql|
        @logger.info("-------------------------------------")
        @logger.info(sql)
        ActiveRecord::Base.connection.execute(sql) unless dryrun
        @logger.info("-------------------------------------")
        @logger.info("")
      end
    end

    def cleansing(output)
      sqls = ""
      output.lines do |line|
        next unless line =~ /^#/
        line = line.gsub(/^# /, '')
        line = line.gsub(/"/, '')
        line = line.strip
        line = line.gsub('serial primary key', 'BIGINT IDENTITY(1,1)' )
        line = line.gsub(/(character varying\(([\d]+)\))/, '\1 encode lzo' )
        line = (line =~ /^ALTER/ ? line + ';' : line)
        line = (line =~ /^DROP/ ? line + ';' : line)
        line = (line =~ /\)$/ ? line + ';' : line)
        sqls += line + "\n"
      end

      timestamp_keys = []
      sql_array = []
      sqls.split(';').each do |sql|
        if sql =~ /^CREATE TABLE/
          lines = sql.strip.lines
          distkey = sql.strip.lines[2].split(' ').first
          sort_keys = lines.map{ |line|
            sort_key = nil
            if line =~ /timestamp,/
              sort_key = line.gsub('timestamp,', '').strip
            end
            if line =~ /date,/
              sort_key = line.gsub('date,', '').strip
            end
            sort_key
          }.compact
          sql = sql.gsub(/\)$/, ",\nPRIMARY KEY(id)\n)")
          sql += "\ndistkey(#{distkey})" if distkey
          sql += "\nsortkey(#{sort_keys.first})" unless sort_keys.empty?
        elsif sql =~ /^ALTER TABLE/
          next if sql =~ / ALTER /
        end
        sql = sql.strip
        sql_array << sql unless sql.empty?
      end
      sql_array
    end
  end
end
