
module ObjectSpace
  class << self
    # Returns all the classes in the object space.
    def classes
      klasses = []
      ObjectSpace.each_object(Class)  { |o| klasses << o }
      klasses
    end
  end
end unless ObjectSpace.respond_to?(:classes)

