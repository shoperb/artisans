module Artisans
  class Error < StandardError; end
  class ArgumentsError < Error; end
  class CompilationError < Error; end
end