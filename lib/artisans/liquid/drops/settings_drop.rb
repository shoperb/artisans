module Artisans
  class SettingsDrop < Liquid::Drop

    attr_reader :settings

    def initialize(settings = {})
      @settings = settings || {}

      @settings.each do |key, value|
        define_singleton_method key do
          format_value(key, value)
        end
      end
    end

    def self.invokable?(method_name)
      true
    end

    def method_missing *args
      nil
    end

    private

    #
    # adding a setting key around value in a comment
    #
    def format_value(key, value)
      "'/*settings.#{key}[*/#{value}/*]*/'"
    end
  end
end