require 'set'
require 'sass-embedded'
require 'liquid'

module Artisans
  class ThemeCompiler
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
        unless file_reader.file_exist?(file_path)
          if file_reader.file_exist?(new_path = file_path+".scss")
            file_path = new_path
          elsif file_reader.file_exist?(new_path = file_path.sub(/\.css\z/,".scss"))
            file_path = new_path
          end
        end
        raise "File not found: #{file_path}" unless file_reader.file_exist?(file_path)
        return "" if loaded.include?(file_path)
        loaded << file_path

        base_dir = File.dirname(file_path)
        output = []
        file_reader.read(file_path).each_line do |line|
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
        if ext = TEST_EXTENSION.detect{|ext| file_reader.file_exist?(path+ext) }
          logger.notify("Do not use \".css.scss\"") if ext.eql?(".css.scss")
          return path+ext
        elsif ext = TEST_EXTENSION.detect{|ext| file_reader.file_exist?(prefix_subfile(path) + ext) }
          logger.notify("Do not use \".css.scss\"") if ext.eql?(".css.scss")
          return prefix_subfile(path) + ext
        elsif file_reader.file_exist?(local = File.join(base_dir, "_"+name+".scss.liquid"))
          return process_liquid(local, name)
        elsif file_reader.file_exist?(local = File.join(base_dir, prefix_subfile(path)+".scss.liquid"))
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
          path = File.join(prefix, fingerprinted)
          if file_reader.digests
            full_path = "#{sources_path}/assets/#{original_path}"
            if file_reader.file_exist?(full_path)
              path = "#{File.dirname(path)}/#{digest(path, file_reader.binread(full_path))}"
            end
          end

          "url('#{path}')"
        end
      end
      
      def process_liquid(local, name)
        dir         = "/tmp/shoperb_cli"
        file_reader.mkdir_p(dir)
        origin_body = file_reader.binread(local)
        digested    = digest(name+".scss", origin_body.to_s + settings.to_s)
        tmp_path    = File.join(dir, digested)
        return tmp_path if file_reader.file_exist?(tmp_path)

        template = Liquid::Template.parse(origin_body)
        liquided = template.render('settings' => settings)
        file_reader.binwrite(tmp_path, liquided)
        tmp_path
      end
    end
  end
end