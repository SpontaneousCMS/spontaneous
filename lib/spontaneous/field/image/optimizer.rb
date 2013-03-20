module Spontaneous::Field
  class Image
    class Optimizer
      def self.run(source_image)
        self.new(source_image).run
      end

      def self.jpegtran_binary
        @jpegtran ||= find_binary("jpegtran")
      end

      def self.jpegoptim_binary
        @jpegoptim ||= find_binary("jpegoptim")
      end

      def self.find_binary(name)
        binary = `which #{name}`.chomp
        return nil if binary.length == 0
        binary
      end

      # def self.find_binary(name)
      #   binaries = ["/usr/bin/env #{name}"]
      #   puts "testing name #{name}"
      #   binaries.detect { |bin| status = Spontaneous.system("#{bin} -h"); p status; status == 1  }.tap do |b|
      #     puts "found #{b.inspect}"
      #   end
      # end

      def initialize(source_image)
        @source_image = source_image
      end

      def run
        jpegoptim!(@source_image)
        jpegtran!(@source_image)
      end

      def jpegoptim!(input)
        run_optimization(self.class.jpegoptim_binary, "-o -q --strip-all --preserve --force #{input} 2>&1 1>/dev/null")
      end

      def jpegtran!(input)
        run_optimization(self.class.jpegtran_binary, "-optimize -progressive -copy none -outfile #{input} #{input}")
      end

      def run_optimization(binary, args)
        return unless binary
        command = [binary, args].join(" ")
        Spontaneous.system(command)
      end
    end
  end
end
