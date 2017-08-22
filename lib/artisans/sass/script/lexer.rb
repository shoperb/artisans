#
# Extending Sass Lexer to understand colors,
# surrounded with settings comments
#
module Artisans
  module SettingsLexer

    def self.prepended(base)
      base.class_eval do
        class << self
          def settings_re(re)
            Regexp::new("(\\'?/\\*settings\\.[a-z_]+\\[\\*/)(" + re.source + ")(/\\*\\]\\*/\\'?)")
          end
        end

        self::REGULAR_EXPRESSIONS[:settings_color] = settings_re(self::REGULAR_EXPRESSIONS[:color])
        self::REGULAR_EXPRESSIONS[:settings_rgb_color] = settings_re(/rgba?\((\d+)\s*,(\d+)\s*,(\d+)\s*,(\d+)?\s*\)/)

        private

        #
        # taken from ::Sass::Script::Lexer
        #
        def token
          if after_interpolation? && (interp = @interpolation_stack.pop)
            interp_type, interp_value = interp
            if interp_type == :special_fun
              return special_fun_body(interp_value)
            else
              raise "[BUG]: Unknown interp_type #{interp_type}" unless interp_type == :string
              return string(interp_value, true)
            end
          end

          #
          # Injecting 'settings_color'
          # lexer check in here
          #
          variable || settings_color || settings_rgb_color || string(:double, false) || string(:single, false) || color || number || id ||
            selector || string(:uri, false) || raw(self.class::UNICODERANGE) || special_fun || special_val ||
            ident_op || ident || op
        end

        #
        # Modified "color" lexer: parses value as valid color.
        # Stores 'representation' along with comments
        #
        def settings_color
          return unless @scanner.match?(self.class::REGULAR_EXPRESSIONS[:settings_color])
          return unless @scanner[2].length == 4 || @scanner[2].length == 7
          scanned_color = scan(self.class::REGULAR_EXPRESSIONS[:settings_color])
          script_color = ::Sass::Script::Value::Color.from_hex(@scanner[2])
          script_color.instance_variable_set("@representation", @scanner[0].gsub(/^'/, '').gsub(/'$/, ''))
          [:color, script_color]
        end

        def settings_rgb_color
          return unless @scanner.match?(self.class::REGULAR_EXPRESSIONS[:settings_rgb_color])
          scanned_color = scan(self.class::REGULAR_EXPRESSIONS[:settings_rgb_color])
          script_color = ::Sass::Script::Value::Color.new([@scanner[3].to_f, @scanner[4].to_f, @scanner[5].to_f, @scanner[6].to_f || 1])
          script_color.instance_variable_set("@representation", @scanner[0].gsub(/^'/, '').gsub(/'$/, ''))
          [:color, script_color]
        end
      end
    end
  end
end

::Sass::Script::Lexer.send(:prepend, Artisans::SettingsLexer)
