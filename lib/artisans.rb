require 'sass'
require 'sprockets'
require 'liquid'
require 'haml'
require 'zip'

require 'artisans/version'
require 'artisans/errors'
require 'artisans/theme_compiler'
require 'artisans/asset_compiler'
require 'artisans/configuration'

module Artisans
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Artisans::Configuration.new
  end
end
