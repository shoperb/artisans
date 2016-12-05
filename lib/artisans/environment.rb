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
    attr_reader :sources_path, :drops, :assets_url, :file_reader

    def initialize **options, &block
      @sources_path = options[:sources_path]
      @drops        = options[:drops]
      @assets_url   = Pathname.new(options[:assets_url])
      @file_reader  = options[:file_reader]

      assets_path   = sources_path.join('assets')

      super(&block)

      # either calculating digest from file content
      # or already existing digests are taken
      context_class.class_eval %Q{
        def asset_path(path, options = {})
          full_path = File.join('#{assets_path}', path)
          if environment.file_reader.respond_to?(:find_digest)
            digest = environment.file_reader.find_digest(full_path)
          else
            digest = Digest::MD5.hexdigest(File.read(full_path)) if File.exists?(full_path)
          end
          ext = File.extname(path)
          File.join('#{assets_url}', "\#{path.gsub(/\#{Regexp.quote(ext)}\\z/, '')}\#{digest}\#{ext}")
        end
      }

      #append_path(assets_path.join('stylesheets'))
      #append_path(assets_path.join('javascripts'))

      custom_importer = Artisans::FileImporters::Custom.new(assets_path.to_s, @file_reader)  if @file_reader
      liquid_importer = Artisans::FileImporters::SassLiquid.new(assets_path.join('stylesheets').to_s, drops, @file_reader)

      self.config = hash_reassoc(config, :paths) do |paths|
        paths.push(assets_path.to_s)
        paths.push(custom_importer)
        paths.push(liquid_importer)
      end

      register_mime_type 'application/font-woff', extensions: ['.woff2']  # not registered by default
      register_mime_type 'application/pdf',       extensions: ['.pdf']    # not registered by default
      register_mime_type 'application/liquid',    extensions: ['.liquid'] # not registered by default

      register_engine '.scss', Artisans::Processors::ScssProcessor
    end

    def cached
      Artisans::CachedEnvironment.new(self)
    end
  end
end

