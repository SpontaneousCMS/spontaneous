Spontaneous::Media::Image.define :webp, [82, 73, 70, 70, nil, nil, nil, nil, 87, 69, 66, 80] do |file|
  file.seek(12)
  format = file.read(4)
  height = width = 0
  uint24 = proc { |bytes| (bytes + 0.chr).unpack("V").first }
  uint14 = proc { |int|  int & 0x3fff }

  case format
  when "VP8 " #simple-file-format-lossy
    file.seek(10, IO::SEEK_CUR)
    # two 14 bit ints with 2 bits of scaling info
    header = file.read(4).unpack("v*")
    width, height = header.map(&uint14)
  when "VP8L" #simple-file-format-lossless
    file.seek(5, IO::SEEK_CUR)
    # two consecutive 14 bit ints
    header = file.read(4).unpack("v*")
    width  = uint14[header[0]] + 1
    height = (header[0] >> 14) + ((header[1] & 0xfff) << 2) + 1
  when "VP8X" #extended-file-format
    file.seek(8, IO::SEEK_CUR)
    width  = uint24[file.read(3)] + 1
    height = uint24[file.read(3)] + 1
  end
  [width, height]
end
