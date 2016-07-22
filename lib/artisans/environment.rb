require_relative 'cached_environment'
require_relative 'file_importers/sass_liquid'
require_relative 'processors/scss_processor'

module Artisans
  #
  # Supplying sprockets environment with correct assets paths, custom file importer for Sass::Engine
  # and custom SassProcessor
  #
  class Environment < ::Sprockets::Environment
    attr_reader :sources_path, :drops

    def initialize **options, &block
      @sources_path = options[:sources_path]
      @drops = options[:drops]
      super(&block)

      context_class.class_eval %Q{
        def asset_path(path, options = {})
          File.join("#{sources_path}",path)
        end
      }

      assets_path = sources_path.join('assets')
      append_path(assets_path)
      append_path(assets_path.join('stylesheets'))
      append_path(assets_path.join('javascripts'))

      importer = Artisans::FileImporters::SassLiquid.new(assets_path.join('stylesheets'), drops)

      self.config = hash_reassoc(config, :paths) { |paths| paths.push(importer) }

      register_engine '.scss', Artisans::Processors::ScssProcessor
    end

    def cached
      Artisans::CachedEnvironment.new(self)
    end
  end
end