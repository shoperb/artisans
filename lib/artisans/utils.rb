module Artisans
  module Utils
    extend self

    def mk_tempfile content, *names
      Tempfile.new(names).tap do |file|
        file.write(content)
        file.flush
        file.open
      end
    end

    def rm_tempfile file
      if file && File.exists?(file)
        file.close
        file.unlink
      end
    end

    def write_file target
      File.open(target, "w+b") { |f| f.write(yield) }
    end
  end
end