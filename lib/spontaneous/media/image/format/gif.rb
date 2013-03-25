Spontaneous::Media::Image.define :gif, [71, 73, 70, 56] do |file|
  file.seek(6)
  file.read(4).unpack('vv')
end
