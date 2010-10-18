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
        img_top = file.read(128)
        file.seek(0,0)
        if img_top =~ /^GIF8[7,9]a/                      then Formats::GIF
        elsif img_top[0, 8] == "\x89PNG\x0d\x0a\x1a\x0a" then Formats::PNG
        elsif img_top[0, 2] == "\xFF\xD8"                then Formats::JPEG
        elsif img_top[0, 2] == 'BM'                      then Formats::BMP
        elsif img_top =~ /^P[1-7]/                       then Formats::PPM
        elsif img_top =~ /\#define\s+\S+\s+\d+/          then Formats::XBM
        elsif img_top[0, 4] == "MM\x00\x2a"              then Formats::TIFF
        elsif img_top[0, 4] == "II\x2a\x00"              then Formats::TIFF
        elsif img_top =~ /\/\* XPM \*\//                 then Formats::XPM
        elsif img_top[0, 4] == "8BPS"                    then Formats::PSD
        elsif img_top[0, 3] == "FWS"                     then Formats::SWF
        elsif img_top[0] == 10                           then Formats::PCX
        else Formats::OTHER
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
          ]

          def read_size
            c_marker = "\xFF"   # Section marker.
            @file.read_o(2)
            while(true)
              marker, code, length = @file.read_o(4).unpack('aan')
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

        class BMP < Abstract
          def read_size
            @file.read_o(26).unpack("x18VV");
          end
        end
        class PPM < Abstract
          def read_size
            header = @file.read_o(1024)
            header.gsub!(/^\#[^\n\r]*/m, "")
              header =~ /^(P[1-6])\s+?(\d+)\s+?(\d+)/m
            width = $2.to_i; height = $3.to_i
            # case $1
            # when "P1", "P4" then @img_type = "PBM"
            # when "P2", "P5" then @img_type = "PGM"
            # when "P3", "P6" then @img_type = "PPM"
            #   #     when "P7"
            #   #       @img_type = "XV"
            #   #       header =~ /IMGINFO:(\d+)x(\d+)/m
            #   #       width = $1.to_i; height = $2.to_i
            # end
            [width, height]
          end
        end
        class XBM < Abstract
          def read_size
            @file.read_o(1024) =~ /^\#define\s*\S*\s*(\d+)\s*\n\#define\s*\S*\s*(\d+)/mi #
              [$1.to_i, $2.to_i]
          end
        end
        class TIFF < Abstract
          def read_size
            endian = if (@file.read_o(4) =~ /II\x2a\x00/o) then 'v' else 'n' end
            # 'v' little-endian   'n' default to big-endian

            packspec = [
              nil,           # nothing (shouldn't happen)
              'C',           # BYTE (8-bit unsigned integer)
              nil,           # ASCII
              endian,        # SHORT (16-bit unsigned integer)
              endian.upcase, # LONG (32-bit unsigned integer)
              nil,           # RATIONAL
              'c',           # SBYTE (8-bit signed integer)
              nil,           # UNDEFINED
              endian,        # SSHORT (16-bit unsigned integer)
              endian.upcase, # SLONG (32-bit unsigned integer)
            ]

            offset = @file.read_o(4).unpack(endian.upcase)[0] # Get offset to IFD

            ifd = @file.read_o(2, offset)
            num_dirent = ifd.unpack(endian)[0]                   # Make it useful
            offset += 2
            num_dirent = offset + (num_dirent * 12);             # Calc. maximum offset of IFD

            ifd = width = height = nil
            while(width.nil? || height.nil?)
              ifd = @file.read_o(12, offset)                 # Get first directory entry
              break if (ifd.nil? || (offset > num_dirent))
              offset += 12
              tag = ifd.unpack(endian)[0]                       # ...and decode its tag
              type = ifd[2, 2].unpack(endian)[0]                # ...and the data type

              # Check the type for sanity.
              next if (type > packspec.size + 0) || (packspec[type].nil?)
              if tag == 0x0100                                  # Decode the value
                width = ifd[8, 4].unpack(packspec[type])[0]
              elsif tag == 0x0101                               # Decode the value
                height = ifd[8, 4].unpack(packspec[type])[0]
              end
            end

            raise "#{if width.nil? then 'width not defined.' end} #{if height.nil? then 'height not defined.' end}" if width.nil? || height.nil?
            [width, height]
      end
    end


    class XPM < Abstract
      def read_size
        width = height = nil
        while(line = @file.read_o(1024))
          if line =~ /"\s*(\d+)\s+(\d+)(\s+\d+\s+\d+){1,2}\s*"/m
            width = $1.to_i; height = $2.to_i
            break
          end
        end
        [width, height]

      end
    end
    class PSD < Abstract
      def read_size
        @file.read_o(26).unpack("x14NN")
      end
    end
    class SWF < Abstract
      def read_size
        header = @file.read_o(9)
        raise("This file is not SWF.") unless header.unpack('a3')[0] == 'FWS'

        bit_length = Integer("0b#{header.unpack('@8B5')}")
        header << @file.read_o(bit_length*4/8+1)
        str = header.unpack("@8B#{5+bit_length*4}")[0]
        last = 5
        x_min = Integer("0b#{str[last,bit_length]}")
        x_max = Integer("0b#{str[(last += bit_length),bit_length]}")
        y_min = Integer("0b#{str[(last += bit_length),bit_length]}")
        y_max = Integer("0b#{str[(last += bit_length),bit_length]}")
        width = (x_max - x_min)/20
        height = (y_max - y_min)/20
        [width, height]
      end
    end
    class PCX < Abstract
      def read_size
        header = @file.read_o(128)
        head_part = header.unpack('C4S4')
        width = head_part[6] - head_part[4] + 1
        height = head_part[7] - head_part[5] + 1
        [width, height]
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

