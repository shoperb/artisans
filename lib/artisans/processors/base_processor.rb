require 'digest'

module Artisans
  class ThemeCompiler
    module BaseProcessor
      attr_accessor :settings, :assets_url, :file_reader, :sources_path
      def initialize(settings:, assets_url:, file_reader:, sources_path:)
        @settings     = settings
        @assets_url   = assets_url
        @file_reader  = file_reader
        @sources_path = sources_path
      end

      def render(file_path)
        file_name = File.basename(file_path)
        body      = expand_requires(file_path)
        [file_name, digest(file_name, body),  body]
      end

      def digest(path, body)
        base     = File.basename(path, ".*")
        ext      = File.extname(path)
        digested = Artisans::ThemeCompiler.hexdigest(body)

        "#{base}-#{digested}#{ext}"
      end
    end
  end
end