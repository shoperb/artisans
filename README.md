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

Artisans::Compiler class is responsible for compiling assets. Just invoke:

```ruby
  Artisans::Compiler.new(my_asset_sources_path, drops_hash).compiled_asset(file_name)  => Sprockets::Asset
  Artisans::Compiler.new(my_asset_sources_path, drops_hash).compiled_source(file_name) => String

  Artisans::Compiler.new(theme.asset_sources_path, { settings: SettingDrop.new }).compiled_source('application.css')
```

in order to compile a _file_name_ in a folder _my_assets_path_ with liquid variabled from a _drops_hash_.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/artisans.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

