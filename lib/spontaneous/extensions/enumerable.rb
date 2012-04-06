# encoding: UTF-8

module Enumerable
  def slice_between(&b)
    Enumerator.new {|y|
      first = true
      buf = []
      prev = nil
      self.each {|elt|
        if first
          first = false
          buf << elt
          prev = elt
        else
          if b.call(prev, elt)
            y << buf
            buf = [elt]
          else
            buf << elt
          end
          prev = elt
        end
      }
      if !buf.empty?
        y << buf
      end
    }
  end
end

