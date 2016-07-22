require_relative 'utils'
require_relative 'asset_compiler'

module Artisans
  class ThemeCompiler

    attr_reader :sources_path, :handle, :compile

    #
    # Handle should be a pathname, as well as sources_path
    #
    def initialize(sources_path:, handle:, drops: {}, compile: nil)
      @sources_path = sources_path.is_a?(String) ? Pathname.new(sources_path) : sources_path
      @handle       = handle
      @compile      = compile || default_compilation_assets

      @compile.keys.each { |k| @compile[k.to_sym] = @compile.delete(k) }
      @asset_compiler = AssetCompiler.new(sources_path: sources_path, drops: drops)
    end

    def zip
      zip = Zip::OutputStream.write_buffer do |out|
        Pathname.glob(sources_path.join("**/*")) do |file|
          pack_file file, out
        end
      end
      Utils.write_file("debug.zip") { zip.string } if Artisans.configuration.verbose
      Utils.mk_tempfile zip.string, "#{handle.basename}-", ".zip"
    end

    # actually not a compiler concern
    # def unzip file
    #   Zip::File.open(file.path) { |zip_file|
    #     raise Error.new("Downloaded file is empty") unless zip_file.entries.any?
    #     directory = zip_file.entries.first.name.split("/").first
    #     zip_file.each { |entry|
    #       entry_name = Pathname.new(entry.name).cleanpath.to_s
    #       name = entry_name.gsub(/\A#{directory}\//, "")
    #       extract_path = Pathname.new(name)

    #       FileUtils.mkdir_p extract_path.dirname
    #       logger.notify "Extracting #{entry_name}" do
    #         entry.extract(extract_path) { true }
    #       end
    #     }
    #   }
    # ensure
    #   Utils.rm_tempfile file
    # end

    private

    def default_compilation_assets
      {
        javascripts: ['application.js'],
        stylesheets: ['application.css']
      }
    end

    def pack_file file, out
      relative_path = file.relative_path_from(sources_path)
      source_path = Pathname.new('sources').join(relative_path)

      case relative_path.to_s
        when /\A(assets\/(stylesheets\/((?:#{compile[:stylesheets].join("|")})\.(css(|\.sass|\.scss)|sass|scss)(\.liquid)?)))\z/
          write_file(out, source_path) { file.read }
          pack_compilable $~, out, "css"
        when /\A(assets\/(javascripts\/((?:#{compile[:javascripts].join("|")})\.(js|coffee|js\.coffee))))\z/
          write_file(out, source_path) { file.read }
          pack_compilable $~, out, "js"
        when /\A((layouts|templates|emails)\/(.*\.liquid))\z/,
             /\A(assets\/((images|icons)\/(.*\.(png|jpg|jpeg|gif|swf|ico|svg|pdf))))\z/,
             /\A(assets\/(fonts\/(.*\.(eot|woff|ttf|woff2))))\z/
          write_file(out, source_path) { file.read }
          write_symlink(out, source_path, relative_path)
        when /\A((layouts|templates|emails)\/(.*\.liquid))\.haml\z/
          write_file(out, source_path) { file.read }
          write_file(out, Pathname.new($1.dup)) { Haml::Engine.new(file.read).render }
        when /\A((presets|config|translations)\/(.*\.json))\z/
          write_file(out, source_path) { file.read }
          write_file(out, file)
        when /\A(assets\/(javascripts\/(.*\.(js|coffee|js\.coffee))))\z/, /\A(assets\/(stylesheets\/(.*\.(css(|\.sass|\.scss)|sass|scss)(\.liquid)?)))\z/
          write_file(out, source_path) { file.read }
      end
    end

    def pack_compilable matchdata, out, type
      compiled = asset_compiler.compiled_source(matchdata[2])
      filename = "#{matchdata[1].gsub(".#{matchdata[4]}", "")}.#{type}"
      puts 'pack compilable ' + filename
      write_file(out, Pathname.new(filename)) { compiled }
    end

    def write_file out, file
      zip_file_path = Pathname.new(handle.basename).join(file)
      out.put_next_entry(zip_file_path)

      content = block_given? ? yield : file.read
      logger.notify "Packing #{file}" do
        out.write content
      end
    end

    def write_symlink out, current, target
      zip_file_path = Pathname.new(handle.basename).join(target)

      entry = out.put_next_entry(zip_file_path)
      entry.instance_variable_set("@ftype", :symlink)
      entry.instance_variable_set("@filepath", target.to_s)
      out.write((handle.basename + current).relative_path_from(handle.basename + target).to_s.gsub(/^..\//, ""))
    end

    def logger
      Artisans.configuration.logger
    end
  end
end