require 'artisans/environment'

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
    require 'digest'
    require 'fileutils'
    module BaseProcessor
      attr_accessor :settings, :assets_url
      def initialize(settings, assets_url)
        @settings   = settings
        @assets_url = assets_url
      end

      def render(file_path)
        file_name = File.basename(file_path)
        body      = expand_requires(file_path)
        [file_name, digest(file_name, body),  body]
      end

      def digest(path, body)
        base     = File.basename(path, ".*")
        ext      = File.extname(path)
        digested = Digest::SHA256.hexdigest(body)[0, 20]  # use first 20 chars like Sprockets

        "#{base}-#{digested}#{ext}"
      end
    end


    require 'set'
    class JSProcessor
      include BaseProcessor

      def expand_requires(file_path, loaded = Set.new)
        raise "File not found: #{file_path}" unless File.exist?(file_path)
        raise "Not supported file format for #{file}" unless TEST_EXTENSION.include?(File.extname(file_path))
        # Avoid loading the same file twice (like sprockets)
        return "" if loaded.include?(file_path)
        loaded << file_path

        base_dir = File.dirname(file_path)
        output = []

        File.readlines(file_path).each do |line|
          if line =~ %r{//=\s*require\s+([^\s]+)}
            required_name = Regexp.last_match(1)

            # Resolve file path
            required_path = resolve_asset_path(required_name, base_dir)
            raise "Required file not found: #{required_name}" unless required_path

            # Recursively expand
            output << expand_requires(required_path, loaded)
          elsif line =~ %r{//=\s*require_}
            raise "NotImplemented line"
          else
            output << line
          end
        end

        output.join
      end

      TEST_EXTENSION = %w[.js]
      def resolve_asset_path(name, base_dir)
        # Try exact filename
        path = File.join(base_dir, name)
        return path if File.exist?(path)

        # Try JS/CSS extensions
        TEST_EXTENSION.each do |ext|
          candidate = File.join(base_dir, "#{name}#{ext}")
          return candidate if File.exist?(candidate)
        end

        nil
      end
    end

    require 'sass-embedded'
    require 'liquid'
    class CSSProcessor
      include BaseProcessor

      def render(file_path)
        out = super

        result = ::Sass.compile_string(out[-1])
        pure_css = result.css
        pure_css = rewrite_asset_urls(pure_css, prefix: assets_url)
        out[-1] = pure_css

        out
      end

      def expand_requires(file_path, loaded = Set.new)
        # try to find matches
        unless File.exist?(file_path)
          if File.exist?(new_path = file_path+".scss")
            file_path = new_path
          elsif File.exist?(new_path = file_path.sub(/\.css\z/,".scss"))
            file_path = new_path
          end
        end
        raise "File not found: #{file_path}" unless File.exist?(file_path)
        return "" if loaded.include?(file_path)
        loaded << file_path

        base_dir = File.dirname(file_path)
        output = []
        File.readlines(file_path).each do |line|
          if line =~ %r{@import\s+\"([^\s]+)\";?}
            required_name = Regexp.last_match(1)

            # Resolve file path
            required_path = resolve_asset_path(required_name, base_dir)
            raise "Required file not found: #{required_name}" unless required_path

            # Recursively expand
            output << expand_requires(required_path, loaded)
          else
            output << line
          end
        end

        output.join
      end

      TEST_EXTENSION = ["", ".css", ".scss", ".css.scss"]
      def resolve_asset_path(name, base_dir)
        # Try exact filename
        path = File.join(base_dir, name)
        if ext = TEST_EXTENSION.detect{|ext| File.exist?(path+ext) }
          logger.notify("Do not use \".css.scss\"") if ext.eql?(".css.scss")
          return path+ext
        elsif ext = TEST_EXTENSION.detect{|ext| File.exist?(prefix_subfile(path) + ext) }
          logger.notify("Do not use \".css.scss\"") if ext.eql?(".css.scss")
          return prefix_subfile(path) + ext
        elsif File.exist?(local = File.join(base_dir, "_"+name+".scss.liquid"))
          return process_liquid(local, name)
        elsif File.exist?(local = File.join(base_dir, prefix_subfile(path)+".scss.liquid"))
          return process_liquid(local, prefix_subfile(path))
        end

        nil
      end

      def prefix_subfile(path)
        path.reverse.sub("/","_/").reverse
      end

      def rewrite_asset_urls(css, prefix:)
        css.gsub(/asset-url\((['"]?)([^'")]+)\1\)/) do
          original_path = Regexp.last_match(2)

          fingerprinted = original_path
          # TODO: add fingerprinting logic based on original_path

          "url('#{File.join(prefix, fingerprinted)}')"
        end
      end
      
      def process_liquid(local, name)
        dir         = "/tmp/shoperb_cli"
        FileUtils.mkdir_p(dir)
        origin_body = File.binread(local)
        digested    = digest(name+".scss", origin_body.to_s + settings.to_s)
        tmp_path    = File.join(dir, digested)
        return tmp_path if File.exist?(tmp_path)

        template = Liquid::Template.parse(origin_body)
        liquided = template.render('settings' => settings)
        File.binwrite(tmp_path, liquided)
        tmp_path
      end
    end

    class DefaultProcessor
      include BaseProcessor

      def expand_requires(file_path)
        File.binread(file_path)
      end
    end

    MIME_PROCESSORS = {
      ".js" => JSProcessor,
      ".css" => CSSProcessor
    }

    module DefaultFileReader
      extend self

      def read(file)
        File.read(file) if File.file?(file)
      end
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
      # @compiled_assets = {}
    end

    def compile_file(file: nil)
      out = {}
      if file
        MIME_PROCESSORS.each do |ending, klass|
          next unless file.ends_with?(ending)
          
          out_file, digested, data = klass.new(settings, assets_url).render(file) 
          out[out_file] = data
        end
        if out.size.eql?(0)
          out_file, digested, data = DefaultProcessor.new(settings, assets_url).render(file)
          out[out_file] = data
        end
      end
      out
    end

    def compiled_files(&block)
      Pathname.glob(sources_path.join("**/*")) do |file|
        p file
        process_file file do |*args|
          logger.notify("Packing #{file}"){ block.call(*args) }
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

    protected
    # attr_accessor :compiled_assets

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
        # when /\A(assets\/(stylesheets\/((?:#{compile_without_ext[:stylesheets].join("|")})\.(css(|\.scss)|scss)(\.liquid)?)))\z/
        #   yield source_path, file_content

        #   compiled = compiled_source($~[2])
        #   filename = "#{$~[1].gsub(".#{$~[4]}", "")}.css"
        #   yield Pathname.new(filename), compiled
        # when /\A(assets\/(javascripts\/((?:#{compile_without_ext[:javascripts].join("|")})\.js)))\z/
        #   yield source_path, file_content

        #   compiled = compiled_source($~[2])
        #   filename = "#{$~[1].gsub(".#{$~[4]}", "")}.js"
        #   yield Pathname.new(filename), compiled
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
        when /\A(assets\/(javascripts\/(.*\.js)))\z/, /\A(assets\/(stylesheets\/(.*\.(css(|\.sass)|sass)(\.liquid)?)))\z/
          yield source_path, file_content
      end
    end

    # def compiled_asset(asset_path)
    #   compiled_assets[asset_path] ||= begin
    #     sprockets_env[asset_path]
    #   rescue StandardError => e
    #     puts e.message
    #     puts e.backtrace

    #     raise Artisans::CompilationError.new(e)
    #   end
    # end

    def logger
      Artisans.configuration.logger
    end

    def sprockets_env
      @sprockets_env ||= Artisans::Environment.new(
        sources_path: sources_path,
        assets_url: assets_url,
        settings: settings,
        file_reader: @file_reader
      )
    end
  end
end
