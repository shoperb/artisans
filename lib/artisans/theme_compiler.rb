require 'artisans/environment'

module Artisans
  class ThemeCompiler

    module DefaultFileReader
      extend self

      def read(file)
        File.read(file) if File.file?(file)
      end
    end

    attr_reader :sources_path, :assets_url, :compile, :drops

    def initialize(sources_path, assets_url, **options)
      @sources_path = sources_path.is_a?(String) ? Pathname.new(sources_path) : sources_path
      @assets_url   = assets_url
      @compile      = options[:compile] || default_compilation_assets
      @drops        = options[:drops] || {}
      @file_reader  = options[:file_reader] || Artisans::ThemeCompiler::DefaultFileReader

      @compile.keys.each { |k| @compile[k.to_sym] = @compile.delete(k) }

      unless drops_valid?(drops)
        raise Artisans::ArgumentsError.new('Drops should be a hash with Liquid::Drop values')
      end

      @compiled_assets = {}
    end

    def compiled_files(&block)
      Pathname.glob(sources_path.join("**/*")) do |file|
        logger.notify "Packing #{file}" do
          process_file file, &block
        end
      end
    end

    def compiled_file_with_derivatives(filename, &block)
      process_file Pathname.new(filename), &block
    end

    def compiled_source(asset_path)
      asset = compiled_asset(asset_path)
      asset ? asset.source : (raise "Asset not found: #{asset_path} in #{sources_path.join('assets')}")
    end

    def rack_response env
      sprockets_env.call(env)
    end

    protected
    attr_accessor :compiled_assets

    def default_compilation_assets
      {
        javascripts: ['application.js'],
        stylesheets: ['application.css']
      }
    end

    def compile_without_ext
      compile.each_with_object({}) do |(type, files), collection|
        collection[type] = files.map{ |f| File.basename(f, '.*') }
      end
    end

    def process_file(file)
      relative_path = file.relative_path_from(sources_path)
      source_path = Pathname.new('sources').join(relative_path)

      file_content = @file_reader.read(file)

      case relative_path.to_s
        when /\A(assets\/(stylesheets\/((?:#{compile_without_ext[:stylesheets].join("|")})\.(css(|\.sass|\.scss)|sass|scss)(\.liquid)?)))\z/
          yield source_path, file_content

          compiled = compiled_source($~[2])
          filename = "#{$~[1].gsub(".#{$~[4]}", "")}.css"
          yield Pathname.new(filename), compiled
        when /\A(assets\/(javascripts\/((?:#{compile_without_ext[:javascripts].join("|")})\.(js|coffee|js\.coffee))))\z/
          yield source_path, file_content

          compiled = compiled_source($~[2])
          filename = "#{$~[1].gsub(".#{$~[4]}", "")}.js"
          yield Pathname.new(filename), compiled
        when /\A((layouts|templates|emails)\/(.*\.liquid))\z/,
             /\A(assets\/((images|icons)\/(.*\.(png|jpg|jpeg|gif|swf|ico|svg|pdf))))\z/,
             /\A(assets\/(fonts\/(.*\.(eot|woff|ttf|woff2))))\z/
          yield relative_path, file_content
          yield source_path, relative_path, type: :symlink
        when /\A((layouts|templates|emails)\/(.*\.liquid))\.haml\z/
          content_compiled = Haml::Engine.new(file_content).render
          yield Pathname.new($1.dup), content_compiled

          if file_content == content_compiled
            yield source_path, Pathname.new($1.dup), type: :symlink
          else
            yield source_path, file_content
          end
        when /\A((presets|config|translations)\/(.*\.json))\z/
          yield relative_path, file_content
          yield source_path, relative_path, type: :symlink
        when /\A(assets\/(javascripts\/(.*\.(js|coffee|js\.coffee))))\z/, /\A(assets\/(stylesheets\/(.*\.(css(|\.sass|\.scss)|sass|scss)(\.liquid)?)))\z/
          yield source_path, file_content
      end
    end

    def compiled_asset(asset_path)
      compiled_assets[asset_path] ||= begin
        sprockets_env[asset_path]
      rescue StandardError => e
        puts e.message
        puts e.backtrace

        raise Artisans::CompilationError.new(e)
      end
    end

    def logger
      Artisans.configuration.logger
    end

    def drops_valid?(drops)
      drops.is_a?(Hash) && drops.values.all?{ |d| d.is_a?(Liquid::Drop) }
    end

    def sprockets_env
      @sprockets_env ||= Artisans::Environment.new(
        sources_path: sources_path,
        assets_url: assets_url,
        drops: drops,
        file_reader: @file_reader
      )
    end
  end
end