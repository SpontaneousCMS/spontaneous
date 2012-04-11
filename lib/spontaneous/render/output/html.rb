module Spontaneous::Render::Output
  class HTML < Spontaneous::Render::Output::Format
    self.register_format(self, :html)
  end
end

