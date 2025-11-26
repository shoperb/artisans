require_relative 'processors/base_processor'
require_relative 'processors/js_processor'
require_relative 'processors/css_processor'
require_relative 'processors/default_processor'

module Artisans
  class ThemeCompiler
    MIMES = %w(.js
    .json
    .xml
    .css
    .html
    .htm
    .txt
    .text
    .yml
    .yaml
    .ico
    .bmp
    .gif
    .webp
    .png
    .jpg
    .jpeg
    .tiff
    .tif
    .svg
    .webm
    .snd
    .au
    .aiff
    .mp3
    .mp2
    .m2a
    .m3a
    .ogx
    .midi
    .mid
    .avi
    .wav
    .wave
    .mp4
    .m4v
    .eot
    .otf
    .ttf
    .woff
    .woff2
    .pdf
    .liquid
    .scss)
    

    MIME_PROCESSORS = {
      ".js" => Artisans::ThemeCompiler::JSProcessor,
      ".css" => Artisans::ThemeCompiler::CSSProcessor
    }

    module DefaultFileReader
      extend self

      def read(file)
        File.read(file) if File.file?(file)
      end
    end

    def self.hexdigest(data)
      Digest::MD5.hexdigest(data)
    end

    DEFAULT_COMPILATION_ASSETS = {
        javascripts: ['application.js'],
        stylesheets: ['application.css']
      }
    attr_reader :sources_path, :compile, :settings
    attr_reader :assets_url # path in CDN

    def initialize(sources_path, assets_url, **options)
      @sources_path = sources_path.is_a?(String) ? Pathname.new(sources_path) : sources_path
      @assets_url   = assets_url
      @compile      = options[:compile] || DEFAULT_COMPILATION_ASSETS
      @settings     = options[:settings] || {}
      @file_reader  = options[:file_reader] || Artisans::ThemeCompiler::DefaultFileReader

      @compile.symbolize_keys!
    end

    def compile_file(file: nil)
      out = {}
      params = {
        settings: settings, 
        assets_url: assets_url, 
        file_reader: @file_reader,
        sources_path: sources_path,
      }
      
      if file
        MIME_PROCESSORS.each do |ending, klass|
          next unless file.ends_with?(ending)
          
          out_file, digested, data = klass.new(**params).render(file) 
          out[out_file] = data
        end
        if out.size.eql?(0)
          out_file, digested, data = DefaultProcessor.new(**params).render(file)
          out[out_file] = data
        end
      end
      out
    end

    def compiled_files(&block)
      Pathname.glob(sources_path.join("**/*")) do |file|
        process_file file do |*args|
          logger.notify("Packing #{file}"){ block.call(*args) }
        end
      end
    end

    protected

    def process_file(file)
      relative_path = file.relative_path_from(sources_path)
      source_path = Pathname.new('sources').join(relative_path)

      file_content = @file_reader.read(file)

      case relative_path.to_s
        when /\A((layouts|templates|emails|sections)\/(.*\.liquid))\z/,
             /\A(assets\/((images|icons)\/(.*\.(png|jpg|jpeg|gif|swf|ico|svg|pdf|json))))\z/,
             /\A(assets\/(fonts\/(.*\.(eot|woff|ttf|woff2|svg))))\z/
          yield relative_path, file_content
          yield source_path, relative_path, :symlink
        when /\A((layouts|templates|emails|sections)\/(.*\.liquid))\.haml\z/
          content_compiled = Haml::Engine.new(file_content).render
          yield Pathname.new($1.dup), content_compiled

          if file_content == content_compiled
            yield source_path, Pathname.new($1.dup), :symlink
          else
            yield source_path, file_content
          end
        when /\A((presets|config|translations)\/(.*\.json))\z/
          yield relative_path, file_content
          yield source_path, relative_path, :symlink
        when /\A(assets\/(javascripts\/(.*\.js)))\z/, /\A(assets\/(stylesheets\/(.*\.(css(|\.scss)|scss)(\.liquid)?)))\z/
          yield source_path, file_content
      end
    end

    def logger
      Artisans.configuration.logger
    end
  end
end
