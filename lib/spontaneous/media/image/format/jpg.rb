Spontaneous::Media::Image.define :jpg, [255, 216] do |file|
  markers = [192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207]
  height = width = 0
  c_marker = 255 # Section marker.
  file.seek(2)
  while(true)
    marker, code, length = file.read(4).unpack('CCn')
    raise "Invalid JPG file: marker not found! '#{file.path}'" if marker != c_marker

    if markers.include?(code)
      height, width = file.read(5).unpack('xnn')
      break
    end
    file.seek(length - 2, IO::SEEK_CUR)
  end
  [width, height]
end
