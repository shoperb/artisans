module Artisans
  class CachedEnvironment < ::Sprockets::CachedEnvironment
    attr_accessor :assets_url
    def initialize(environment)
      self.assets_url = environment.assets_url
      super(environment)
    end
  end
end
