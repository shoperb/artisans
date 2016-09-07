#
# In case if default sass importer fails to retrive a file with @import command (like any scss.liquid file)
# it falls back to next registered file importers, namely this one.
# Artisans::FileImporters::SassLiquid class retrives the liquid file, parses it and returnes
# the contend to sass engine, which is able to proceed further.
#
module Artisans
  module FileImporters
    class SassLiquid < Sass::Importers::Filesystem

      attr_reader :drops

      def initialize(root, drops)
        super(root)

        @drops = drops
        @drops.keys.each { |k| @drops[k.to_s] = @drops.delete(k) }
      end

      alias_method :to_str, :to_s
      protected

      def extensions
        {
          'sass.liquid' => :sass,
          'scss.liquid' => :scss
        }
      end

      private

      def _find(dir, name, options)
        #
        # starts as the original function
        #
        full_filename, syntax = ::Sass::Util.destructure(find_real_file(dir, name, options))
        return unless full_filename && File.readable?(full_filename)

        full_filename = full_filename.tr("\\", "/") if Sass::Util.windows?

        options[:syntax]   = syntax
        options[:filename] = full_filename
        options[:importer] = self

        #
        # below goes the modification of original function
        #
        file_content    = File.read(full_filename)
        liquid_compiled = Liquid::Template.parse(file_content).render(drops)

        Sass::Engine.new(liquid_compiled, options)
      end
    end
  end
end
