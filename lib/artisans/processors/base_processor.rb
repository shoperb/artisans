require 'digest'
require 'fileutils'

module Artisans
  class ThemeCompiler
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
  end
end