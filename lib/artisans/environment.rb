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
          reader = environment.file_reader

          digest = reader.try(:find_digest, full_path)
          digest ||= Digest::MD5.hexdigest(File.read(full_path)) if File.exists?(full_path)

          separator = reader.try(:find_separator, full_path)
          separator ||= ''

          ext = File.extname(path)
          filename = [path.gsub(/\#{Regexp.quote(ext)}\\z/, ''), separator, digest, ext].map(&:presence).compact.join
          File.join('#{assets_url}', filename)
        end
      }

      # regular paths, used for RTE, for file-system compilation
      env_paths = [
        assets_path,
        assets_path.join('stylesheets'),
        assets_path.join('javascripts')
      ]

      env_paths.each do |p|
        append_path p
      end

      # extended path, which can delegate to database file reader
      customer_importers = []

      if @file_reader
        env_paths.each do |p|
          customer_importers << Artisans::FileImporters::Custom.new(p.to_s, @file_reader)
        end
      end

      # custom importer for both cases
      liquid_importer = Artisans::FileImporters::SassLiquid.new(assets_path.join('stylesheets').to_s, drops, @file_reader)

      self.config = hash_reassoc(config, :paths) do |paths|
        paths.push(assets_path.to_s)
        customer_importers.each { |i| paths.push(i) }
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

