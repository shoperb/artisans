module Artisans
  class ThemeCompiler

    attr_reader :sources_path, :compile, :drops

    def initialize(sources_path, drops: {}, compile: nil)
      @sources_path = sources_path.is_a?(String) ? Pathname.new(sources_path) : sources_path
      @compile      = compile || default_compilation_assets
      @drops        = drops

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
      compiled_asset(asset_path).source
    end

    private
    attr_accessor :compiled_assets

    def default_compilation_assets
      {
        javascripts: ['application'],
        stylesheets: ['application']
      }
    end

    def process_file(file)
      relative_path = file.relative_path_from(sources_path)
      source_path = Pathname.new('sources').join(relative_path)

      case relative_path.to_s
        when /\A(assets\/(stylesheets\/((?:#{compile[:stylesheets].join("|")})\.(css(|\.sass|\.scss)|sass|scss)(\.liquid)?)))\z/
          yield source_path, file.read

          compiled = compiled_source($~[2])
          filename = "#{$~[1].gsub(".#{$~[4]}", "")}.css"
          yield Pathname.new(filename), compiled
        when /\A(assets\/(javascripts\/((?:#{compile[:javascripts].join("|")})\.(js|coffee|js\.coffee))))\z/
          yield source_path, file.read

          compiled = compiled_source($~[2])
          filename = "#{$~[1].gsub(".#{$~[4]}", "")}.js"
          yield Pathname.new(filename), compiled
        when /\A((layouts|templates|emails)\/(.*\.liquid))\z/,
             /\A(assets\/((images|icons)\/(.*\.(png|jpg|jpeg|gif|swf|ico|svg|pdf))))\z/,
             /\A(assets\/(fonts\/(.*\.(eot|woff|ttf|woff2))))\z/
          yield source_path, file.read
          yield relative_path, source_path, type: :symlink
        when /\A((layouts|templates|emails)\/(.*\.liquid))\.haml\z/
          yield source_path, file.read
          yield Pathname.new($1.dup), Haml::Engine.new(file.read).render
        when /\A((presets|config|translations)\/(.*\.json))\z/
          yield source_path, file.read
          yield relative_path, source_path, type: :symlink
        when /\A(assets\/(javascripts\/(.*\.(js|coffee|js\.coffee))))\z/, /\A(assets\/(stylesheets\/(.*\.(css(|\.sass|\.scss)|sass|scss)(\.liquid)?)))\z/
          yield source_path, file.read
      end
    end

    def compiled_asset(asset_path)
      compiled_assets[asset_path] ||= begin
        sprockets_env[asset_path]
      rescue StandardError => e
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
      @sprockets_env ||= Artisans::Environment.new(sources_path: sources_path, drops: drops)
    end
  end
end