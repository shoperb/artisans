require_relative 'environment'

#
# Artisans::AssetCompiler class accepts as an argument a path to asset sources (not compiled) and
# the set of liquid drops, with which assets should be customized. Important: if the source assets
# folder includes already compiled asset, then this compiled asset will be returned by default.
#
module Artisans
  class AssetCompiler

    attr_reader :drops, :sources_path

    def initialize(sources_path:, drops: {})
      @drops        = drops
      @sources_path = sources_path.is_a?(String) ? Pathname.new(sources_path) : sources_path

      unless drops_valid?(drops)
        raise Artisans::ArgumentsError.new('Drops should be a hash with Liquid::Drop values')
      end

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

    def sprockets_env
      @sprockets_env ||= Artisans::Environment.new(sources_path: sources_path, drops: drops)
    end

    def drops_valid?(drops)
      drops.is_a?(Hash) && drops.values.all?{ |d| d.is_a?(Liquid::Drop) }
    end
  end
end
