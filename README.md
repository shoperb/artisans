# Artisans

Artisans is a gem that helps to compile stylesheets assets in a format of scss.liquid, which might contain settings.
The main job of this gem is:
  - To help existing sprocket FileImporter to locate scss files (@import directive), which has scss.liquid extension
  - To make existing Sass compiler keep inline comments, which include pattern 'settings.xxx'

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'artisans'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install artisans

## Usage

The gem can be used for compiling single assets (used directly in shoperb during theme editing) and compiling (and packing to .zip) the whole theme.

Single asset compiling generally looks as following:

```ruby
compiler = Artisans::ThemeCompiler.new(theme_sources_path, theme_assets_url, drops: liquid_drops_hash)

compiled_output = compiler.compiled_source('source/file/path')

# compiling whole theme. ThemeCompiler#compiled_file_with_derivatives yields every result file one by one
compiler.compiled_files do |file_path, content, type: :file|
  # type might be :symlink. type = :file is default
end

# compilation of only 1 file with its derivatives is also possible:
# in this case compilation of sources/emails.liquid.haml will result in:
# - sources/emails/xxx.liquid.haml -> just returns source itself
# - emails/xxx.liquid -> compiled version
#
# Compilation of 'sources/translations/en.json' will result in:
# - sources/translations/en.json -> the source itself
# - translations/en.json -> a symlink to the source
#
# Compilation of sources/stylesheets/application.sass.liquid will result in:
# - sources/stylesheets/application.sass.liquid
# - stylesheets/application.css

compiler.compiled_file_with_derivatives('path/to/source') do |file_path, content, type: :file|
  # type might be :symlink. type = :file is default
end

```

Artisans gem have could of configs as well:

```ruby
Artisans.configure do |c|
  c.verbose = false # by default
  c.logger = MyCustomLogger # which should implement #notify method
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/artisans.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

