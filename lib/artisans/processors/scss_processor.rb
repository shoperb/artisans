#
# Artisans::Processors::ScssProcessor inherits all functionality of built-it
# sprockets scss processors class.
# Artisans::Processors::ScssProcessor is intended to integerate custom file importer (FileIMporters::SassLiquid),
# which is able to @import liquid files. In addition, ScssProcessor processed correctly
# inline comments in scss file.
#
module Artisans
  module Processors
    class ScssProcessor < Sprockets::ScssProcessor

      #
      # Inherits default scss compiling.
      # + Removes quates, which were artificially places around settings comments so the processor leaves them.
      # "/*setting.setting_name[*/setting_value/*]*/" => /*setting.setting_name[*/setting_value/*]*/
      #
      def call(input)
        super.tap do |hash|
          hash[:data] = hash[:data].gsub(/"(\/\*settings\..+\[.+\]\*\/)"/, '\1')
        end
      end
    end
  end
end
