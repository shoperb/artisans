module Artisans
  module FileImporters
    class Custom < Sass::Importers::Filesystem

      attr_reader :file_reader

      def initialize(root, file_reader)
        super(root)

        @root = root.to_s
        @real_root = Sass::Util.realpath(@root).to_s

        @file_reader = file_reader
      end

      alias_method :to_str, :to_s

      protected

      def _find(dir, name, options)
        if @file_reader.respond_to?(:find_real_file)
          full_filename, syntax = @file_reader.find_real_file(dir, name, options, extensions)
        else
          full_filename, syntax = Sass::Util.destructure(find_real_file(dir, name, options))
        end
        return unless full_filename

        options[:syntax] = syntax
        options[:filename] = full_filename
        options[:importer] = self

        Sass::Engine.new(@file_reader.read(full_filename), options)
      end
    end
  end
end