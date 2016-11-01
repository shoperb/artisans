require_relative 'file_importers/sass_liquid'
require_relative 'file_importers/custom'

require_relative 'processors/scss_processor'
require_relative 'cached_environment'

module Artisans
  #
  # Supplying sprockets environment with correct assets paths, custom file importer for Sass::Engine
  # and custom SassProcessor
  #
  class Environment < ::Sprockets::Environment
    attr_reader :sources_path, :drops, :assets_url

    def initialize **options, &block
      @sources_path = options[:sources_path]
      @drops        = options[:drops]
      @assets_url   = Pathname.new(options[:assets_url])
      @file_reader  = options[:file_reader]

      assets_path   = sources_path.join('assets')

      super(&block)

      context_class.class_eval %Q{
        def asset_path(path, options = {})
          File.join(assets_path.to_s,path)
        end
      }

      append_path(assets_path)
      #append_path(assets_path.join('stylesheets'))
      #append_path(assets_path.join('javascripts'))

      custom_importer = Artisans::FileImporters::Custom.new(assets_path.join('stylesheets'), @file_reader)
      liquid_importer = Artisans::FileImporters::SassLiquid.new(assets_path.join('stylesheets'), drops, @file_reader)

      self.config = hash_reassoc(config, :paths) do |paths|
        paths.push(custom_importer)
        paths.push(liquid_importer)
      end

      register_engine '.scss', Artisans::Processors::ScssProcessor
    end

    def cached
      Artisans::CachedEnvironment.new(self)
    end
  end
end

