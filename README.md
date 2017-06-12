# redshiftex [![Build Status](https://secure.travis-ci.org/toyama0919/redshiftex.png?branch=master)](http://travis-ci.org/toyama0919/redshiftex)

TODO: Summary

## Examples(copy)

    $ redshiftex copy -c config/database.yml -E development_redshift --copy_option "DATEFORMAT 'YYYY-MM-DD' TIMEFORMAT 'YYYY-MM-DD HH:MI:SS' json 'auto' GZIP TRUNCATECOLUMNS maxerror 100" --path "s3://${bucket_name}/pageview." --table pageview

## Examples(copy_all)

    $ bundle exec redshiftex copy_all -c config/database.yml -E stg1 --copy_option "json 'auto' GZIP TRUNCATECOLUMNS maxerror 100 DATEFORMAT 'auto'" --path "s3://${bucket_name}/logs/<%=table%>." --excludes 'table_1' 'table_2'

## Examples(diff)

    $ redshiftex ridgepole diff -c config/database.yml -E stg --schemafile Schemafile

## Installation

Add this line to your application's Gemfile:

    gem 'redshiftex'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redshiftex

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Information

* [Homepage](https://github.com/toyama0919/redshiftex)
* [Issues](https://github.com/toyama0919/redshiftex/issues)
* [Documentation](http://rubydoc.info/gems/redshiftex/frames)
* [Email](mailto:toyama0919@gmail.com)

## Copyright

Copyright (c) 2015 Hiroshi Toyama

See [LICENSE.txt](../LICENSE.txt) for details.
