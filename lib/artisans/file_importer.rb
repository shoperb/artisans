module Artisans
  class FileImporter
    attr_reader :file_reader

    def initialize(root, environment)
      @root = root.to_s
      @file_reader = environment.file_reader
    end

    def method_missing(*args)
      binding.pry
    end

    def to_s
      @root
    end

    alias_method :to_str, :to_s
    alias_method :to_path, :to_s

    def find(dir, name, options)
      #_find(dir, name, options)
      "dedwewed"
    end

    protected

    def _find(dir, name, options)
      if @file_reader.respond_to?(:find_real_file)
        full_filename, syntax = @file_reader.find_real_file(dir, name, options, extensions)
      else
        full_filename, syntax = ::Sass::Util.destructure(find_real_file(dir, name, options))
      end
      return unless full_filename

      options[:syntax] = syntax
      options[:filename] = full_filename
      options[:importer] = self

      ::Sass::Engine.new(@file_reader.read(full_filename), options)
    end
  end

end
