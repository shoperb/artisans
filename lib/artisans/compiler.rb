require_relative 'file_importers/sass_liquid'
require_relative 'processors/scss_processor'

module Artisans
  class Compiler
    attr_reader :drops, :asset_path
    
    STYLESHEET_PATH = 'application.css.scss'

    def initialize(asset_path, drops = {})
      raise Artisans::ArgumentsError.new('Drops should be a hash') unless drops.is_a?(Hash)
      raise Artisans::ArgumentsError.new('Drops should be of a Liquid::Drop class') unless 
        drops.values.all?{ |d| d.is_a?(Liquid::Drop) }

      @drops      = drops
      @asset_path = asset_path.is_a?(String) ? Pathname.new(asset_path) : asset_path

      @compiled_assets = {}
    end

    def compiled_source(asset_path)
      compiled_asset(asset_path).source
    end

    def compiled_asset(asset_path)
      @compiled_assets[asset_path] ||= sprockets_env[asset_path]
    end

    private

    def sprockets_env
      @sprockets_env ||= Sprockets::Environment.new do |env|

        env.context_class.class_eval %Q{
          def asset_path(path, options = {})
            File.join("#{asset_path}",path)
          end
        }
          
        env.append_path(asset_path.join('stylesheets'));
        env.append_path(asset_path.join('javascripts'));

        importer = Artisans::FileImporters::SassLiquid.new(asset_path.join('stylesheets'), drops)

        # push the importer to frozer hash :)))
        env.config = env.hash_reassoc(env.config, :paths) {|paths| paths.push(importer)}
        env.register_engine '.scss', Artisans::Processors::ScssProcessor
      end
    end
  end
end