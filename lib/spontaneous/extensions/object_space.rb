
module ObjectSpace
  class << self
    # Returns all the classes in the object space.
    def classes
      klasses = []
      ObjectSpace.each_object(Class)  { |o| klasses << o }
      klasses
    end

    def modules
      modules = []
      ObjectSpace.each_object(Module)  { |o| modules << o }
      modules
    end
  end
end unless ObjectSpace.respond_to?(:classes)

