module Artisans
  class Configuration

    attr_accessor :verbose, :logger

    def initialize(*)
      @verbose = false
      @logger  = Logger.new(STDOUT).tap do |logger|
        logger.define_singleton_method(:notify) do |msg, &block|
          info msg
          block.call
        end
      end
    end
  end
end
