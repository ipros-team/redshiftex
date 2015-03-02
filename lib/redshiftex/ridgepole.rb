require "thor"
require 'yaml'
require 'active_record'
require 'ridgepole'
require 'ridgepole/cli/config'

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
      @yaml = @core.connection(@class_options['config'], @class_options['environment'])
      @logger = @core.logger
    end

    desc "apply", "apply"
    def apply
      get_sql_diff.each do |sql|
        @logger.info(sql)
        ActiveRecord::Base.connection.execute(sql)
      end
    end

    desc "diff", "diff"
    def diff
      get_sql_diff.each do |sql|
        @logger.info(sql)
      end
    end

    private

    def get_delta
      ::Ridgepole::Client.diff(
        ::Ridgepole::Config.load(@class_options['config'], @class_options['environment']),
        File.open(@class_options['schemafile']), {}
      )
    end

    def get_sql_diff
      delta = get_delta
      migrated, sql = delta.migrate(:noop => true)
      sqls = sql.lines.map{ |line| line.strip }
      cleansing(sqls)
    end

    def cleansing(sqls)
      timestamp_keys = []
      sql_array = []
      sqls.each do |sql|
        sql = sql.gsub("serial primary key", "BIGINT")
        sql = sql.gsub(/(character varying\(([\d]+)\))/, '\1 encode lzo' )
        if sql =~ /^CREATE TABLE/
          r = / \((.*)\)/
          columns = sql.scan(r).first.first.split(',')

          distkey = columns[1].split(' ').first
          sort_keys = columns.map{ |column|
            column = column.strip
            sort_key = nil
            if column =~ / timestamp$/
              sort_key = column.split(' ').first
            end
            if column =~ / date$/
              sort_key = column.split(' ').first
            end
            sort_key
          }.compact
          sql = sql.gsub(/\)$/, ", PRIMARY KEY(id))")
          sql += " distkey(#{distkey})" if distkey
          sql += " sortkey(#{sort_keys.first})" unless sort_keys.empty?
        elsif sql =~ /^ALTER TABLE/
          next if sql =~ / ALTER /
        end
        sql = sql + ';'
        sql_array << sql unless sql.empty?
      end
      sql_array
    end
  end
end
