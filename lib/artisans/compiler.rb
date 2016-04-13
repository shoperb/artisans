require_relative 'file_importers/sass_liquid'
require_relative 'processors/scss_processor'

#
# Artisans::Compiler class accepts as an argument a path to asset sources (not compiled) and
# the set of liquid drops, with which assets should be customized. Important: if the source assets
# folder includes already compiled asset, then this compiled asset will be returned by default.
#
module Artisans
  class Compiler
    attr_reader :drops, :sources_path

    def initialize(sources_path, drops = {})
      raise Artisans::ArgumentsError.new('Drops should be a hash') unless drops.is_a?(Hash)
      raise Artisans::ArgumentsError.new('Drops should be of a Liquid::Drop class') unless 
        drops.values.all?{ |d| d.is_a?(Liquid::Drop) }

      @drops = drops
      @sources_path = sources_path.is_a?(String) ? Pathname.new(sources_path) : sources_path

      @compiled_assets = {}
    end

    def compiled_source(asset_path)
      compiled_asset(asset_path).source
    end

    def compiled_asset(asset_path)
      compiled_assets[asset_path] ||= begin
        sprockets_env[asset_path]
      rescue StandardError => e
        raise Artisans::CompilationError.new(e)
      end
    end

    private
    attr_accessor :compiled_assets

    #
    # Supplying sprockets environment with correct assets paths, custom file importer for Sass::Engine
    # and custom SassProcessor
    #
    def sprockets_env
      @sprockets_env = Sprockets::Environment.new do |env|

        env.context_class.class_eval %Q{
          def asset_path(path, options = {})
            File.join("#{sources_path}",path)
          end
        }
        
        env.append_path(sources_path)
        env.append_path(sources_path.join('stylesheets'))
        env.append_path(sources_path.join('javascripts'))

        importer = Artisans::FileImporters::SassLiquid.new(sources_path.join('stylesheets'), drops)

        # push the importer to frozer hash :)))
        env.config = env.hash_reassoc(env.config, :paths) {|paths| paths.push(importer)}
        env.register_engine '.scss', Artisans::Processors::ScssProcessor
      end
    end
  end
end
