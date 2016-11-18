module Artisans
  class CachedEnvironment < ::Sprockets::CachedEnvironment
    attr_accessor :assets_url, :environment, :file_reader

    def initialize(environment, options={})
      @assets_url  = environment.assets_url
      @environment = environment
      @file_reader = environment.file_reader
      super(environment)
    end

    def stat(filename)
      if file_reader.respond_to?(:stat)
        file_reader.stat(filename)
      else
        super(filename)
      end
    end

    def read_file(filename, content_type)
      @file_reader.read(filename)
    end

    def load_from_unloaded(unloaded, force_native = false)
      if file_reader.respond_to?(:load_from_unloaded) && !force_native
        file_reader.load_from_unloaded(unloaded, self)
      else
        super(unloaded)
      end
    end

    def resolve_absolute_path(paths, filename, accept)
      if file_reader.respond_to?(:resolve_absolute_path)
        file_reader.resolve_absolute_path(paths, filename, accept, self)
      else
        super(paths, filename, accept)
      end
    end

    def load(uri, force_native = false)
      if file_reader.respond_to?(:load) && !force_native
        file_reader.load(uri, self)
      else
        super(uri)
      end
    end

    def file?(uri)
      if file_reader.respond_to?(:file?)
        file_reader.file?(uri)
      else
        super(uri)
      end
    end

    def path_matches(load_path, logical_name, logical_basename)
      if load_path.respond_to?(:file_reader) && load_path.file_reader.respond_to?(:path_matches)
        load_path.file_reader.path_matches(load_path, logical_name, logical_basename)
      else
        super(load_path, logical_name, logical_basename)
      end
    end
  end
end
