require 'set'

module Artisans
  class ThemeCompiler
    class JSProcessor
      include BaseProcessor

      def expand_requires(file_path, loaded = Set.new)
        raise "File not found: #{file_path}" unless file_reader.file_exist?(file_path)
        raise "Not supported file format for #{file}" unless TEST_EXTENSION.include?(File.extname(file_path))
        # Avoid loading the same file twice (like sprockets)
        return "" if loaded.include?(file_path)
        loaded << file_path

        base_dir = File.dirname(file_path)
        output = []

        file_reader.read(file_path).each_line.each do |line|
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
        return path if file_reader.file_exist?(path)

        # Try JS/CSS extensions
        TEST_EXTENSION.each do |ext|
          candidate = File.join(base_dir, "#{name}#{ext}")
          return candidate if file_reader.file_exist?(candidate)
        end

        nil
      end
    end
  end
end