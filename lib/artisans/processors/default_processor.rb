module Artisans
  class ThemeCompiler
    class DefaultProcessor
      include BaseProcessor

      def expand_requires(file_path)
        File.binread(file_path)
      end
    end
  end
end