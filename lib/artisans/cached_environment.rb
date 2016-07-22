module Artisans
  class CachedEnvironment < ::Sprockets::CachedEnvironment
    attr_accessor :sources_path, :drops

    def initialize(environment)
      @sources_path = environment.sources_path
      @drops = environment.drops
      super(environment)
    end
  end
end