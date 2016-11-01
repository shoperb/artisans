module Artisans
  module FileImporters
    class Custom < Sass::Importers::Filesystem

      def initialize(root, file_reader)
        super(root)

        @file_reader = file_reader
      end

      alias_method :to_str, :to_s

      protected

      def _find(dir, name, options)
        full_filename, syntax = Sass::Util.destructure(find_real_file(dir, name, options))
        return unless full_filename && File.readable?(full_filename)

        # TODO: this preserves historical behavior, but it's possible
        # :filename should be either normalized to the native format
        # or consistently URI-format.
        full_filename = full_filename.tr("\\", "/") if Sass::Util.windows?

        options[:syntax] = syntax
        options[:filename] = full_filename
        options[:importer] = self
        Sass::Engine.new(@file_reader.read(full_filename), options)
      end
    end
  end
end