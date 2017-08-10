#
# Artisans::Sass::SassLiquidImporter can read .scss.liquid files, and at the same time
# using custom 'file_reader' provided along with the environment
#
module Artisans
  module Sass
    class SassLiquidImporter < ::Sass::Importers::Filesystem

      def initialize(root, environment = nil)
        super(root)

        @root = root.to_s
        @real_root = ::Sass::Util.realpath(@root).to_s

        @environment = environment
      end

      alias_method :to_str, :to_s
      protected

      def extensions
        super.merge(
          'sass.liquid' => :sass,
          'scss.liquid' => :scss
        )
      end

      def _find(dir, name, options)
        return unless @environment

        if @environment.file_reader.respond_to?(:find_real_file)
          full_filename, syntax = @environment.file_reader.find_real_file(dir, name, options, extensions)
        else
          full_filename, syntax = ::Sass::Util.destructure(find_real_file(dir, name, options))
        end
        return unless full_filename

        full_filename = full_filename.tr("\\", "/") if ::Sass::Util.windows?

        options[:syntax]   = syntax
        options[:filename] = full_filename
        options[:importer] = self

        #
        # below goes the modification of original function
        #
        file_content = @environment.read_file(full_filename)

        if File.extname(full_filename) == '.liquid'
          liquid_compiled = Liquid::Template.parse(file_content).render(@environment.drops)
          ::Sass::Engine.new(liquid_compiled, options)
        else
          ::Sass::Engine.new(file_content, options)
        end
      end
    end
  end
end