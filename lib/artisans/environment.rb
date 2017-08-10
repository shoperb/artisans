require_relative 'cached_environment'
require_relative 'liquid/drops/settings_drop'

require_relative 'sass/sass_liquid_importer'
require_relative 'sass/settings_processor'
require_relative 'sass/script/lexer'

module Artisans
  #
  # Supplying sprockets environment with correct assets paths, custom file importer for Sass::Engine
  # and custom SassProcessor
  #
  class Environment < ::Sprockets::Environment
    attr_reader :sources_path, :settings, :assets_url, :file_reader

    def initialize **options, &block
      @sources_path = options[:sources_path]
      @settings     = options[:settings]

      @assets_url   = Pathname.new(options[:assets_url])
      @file_reader  = options[:file_reader]

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

      # cant use 'append_path' with objects importers, so:
      self.config = hash_reassoc(config, :paths) do |paths|
        paths.push(assets_path.to_s)
        paths.push(stylesheets_path)
        paths.push(javascripts_path)

        paths.push(sass_liquid_importer)
      end

      register_mime_type 'application/font-woff', extensions: ['.woff2']  # not registered by default
      register_mime_type 'application/pdf',       extensions: ['.pdf']    # not registered by default
      register_mime_type 'application/liquid',    extensions: ['.liquid'] # not registered by default

      register_engine '.scss', Artisans::Sass::SettingsProcessor
    end

    def drops
      @drops ||= {
        settings: SettingsDrop.new(settings)
      }.stringify_keys
    end

    def read_file(filename)
      cached.read_file(filename)
    end

    private

    def sass_liquid_importer
      Artisans::Sass::SassLiquidImporter.new(stylesheets_path, self)
    end

    def assets_path
      @assets_path ||= sources_path.join('assets')
    end

    def stylesheets_path
      @stylesheets_path ||= assets_path.join('stylesheets').to_s
    end

    def javascripts_path
      @javascripts_path ||= assets_path.join('javascripts').to_s
    end

    def cached
      @cached ||= Artisans::CachedEnvironment.new(self)
    end
  end
end
