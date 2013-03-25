Spontaneous::Media::Image.define :png, [137, 80, 78, 71, 13, 10, 26, 10] do |file|
  file.seek(16)
  file.read(8).unpack('NN')
end
