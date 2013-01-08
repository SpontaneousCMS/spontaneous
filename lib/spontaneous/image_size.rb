# encoding: UTF-8

module Spontaneous
  module ImageSize
    def self.read(file)
      reader = ImageReader.new(file)
      reader.size
    end

    class ImageReader

      def initialize(file)
        if file.kind_of? IO
          read_size(file)
        else
          File.open(file, 'rb') { |io| read_size(io) }
        end
      end

      def read_size(file)
        klass = image_type(file)
        @image = klass.new(file)
      end

      def image_type(file)
        return Formats::EMPTY if file.size == 0
        img_top = file.read(16)
        bytes = img_top.unpack("C*")
        file.seek(0,0)
        if img_top =~ /^GIF8[7,9]a/
          Formats::GIF
        elsif bytes[0, 8] == [137, 80, 78, 71, 13, 10, 26, 10]
          Formats::PNG
        elsif bytes[0, 2] == [255, 216]
          Formats::JPEG
        else
          Formats::OTHER
        end
      end

      def size
        @image.size
      end

      module Formats
        class Abstract
          def initialize(file)
            @file = file
            def @file.read_o(length = 1, offset = nil)
              self.seek(offset, 0) if offset
              ret = self.read(length)
              raise "cannot read!!" unless ret
              ret
            end
            # read size straight away so that if file is closed we don't raise an error
            @size = read_size
          end
          def size
            @size
          end

          def read_size
            [0,0]
          end
        end

        class EMPTY
          def initialize(file)
          end
          def size
            [0, 0]
          end
        end
        class GIF < Abstract
          def read_size
            @file.read_o(6)
            @file.read_o(4).unpack('vv')
          end
        end

        class JPEG < Abstract
          JPEGCodeCheck = [
            "\xc0", "\xc1", "\xc2", "\xc3",
            "\xc5", "\xc6", "\xc7",
            "\xc9", "\xca", "\xcb",
            "\xcd", "\xce", "\xcf",
          ].map { |c| c.unpack('C').first }

          def read_size
            c_marker = 255 # Section marker.

            @file.read_o(2)
            while(true)
              marker, code, length = @file.read_o(4).unpack('CCn')
              raise "JPEG marker not found!" if marker != c_marker

              if JPEGCodeCheck.include?(code)
                height, width = @file.read_o(5).unpack('xnn')
                return([width, height])
              end
              @file.read_o(length - 2)
            end
          end
        end
        class PNG < Abstract
          def read_size
            @file.read_o(12)
            raise "This file is not PNG." unless @file.read_o(4) == "IHDR"
            @file.read_o(8).unpack('NN')
          end
        end



        class OTHER < Abstract
          def read_size
            [0,0]
          end
        end
      end
    end
  end
end
