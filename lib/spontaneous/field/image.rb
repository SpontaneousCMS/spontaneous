# encoding: UTF-8

require 'tempfile'
require 'mini_magick'
require 'delegate'


module Spontaneous::Field
  class Image < File
    autoload :Utilities, 'spontaneous/field/image/utilities'
    autoload :Attributes, 'spontaneous/field/image/attributes'
    autoload :Optimizer, 'spontaneous/field/image/optimizer'
    autoload :Processor, 'spontaneous/field/image/processor'

    has_editor
    include Utilities

    def self.accepts
      %w{image/(png|jpeg|gif)}
    end

    def self.size(name, &process)
      self.sizes[name.to_sym] = process

      unless method_defined?(name)
        class_eval <<-IMAGE
            def #{name}
              sizes[:#{name}]
            end
            IMAGE
      end
    end

    def self.sizes
      size_definitions
    end

    def self.validate_sizes(sizes)
      sizes
    end

    def self.size_definitions
      @size_definitions ||= superclass.respond_to?(:size_definitions) ? superclass.size_definitions.dup : { :__ui__ => ui_preview_size }
    end

    def self.ui_preview_size
      Proc.new {
        width 300
      }
    end

    def image?
      true
    end

    def sizes
      @sizes ||= Hash.new { |hash, key| hash[key] = Attributes.new(processed_values[key]) }
    end

    # value used to show conflicts between the current value and the value they're attempting to enter
    def conflicted_value
      value
    end

    def serialize_pending_file(file)
      attrs = Processor.new(file).serialize
      attrs.delete(:path)
      attrs.merge(super)
    end

    def page_lock_description
      "Processing image '#{pending_value[:value][:filename]}'"
    end

    # original is special and should always be defined
    def original
      @original ||= sizes[:original]
    end

    def width
      original.width
    end

    def height
      original.height
    end

    def filesize
      original.filesize
    end

    def src
      original.src
    end

    def filepath
      unprocessed_value
    end

    # formats are irrelevant to image/file fields
    def outputs
      [:original, :__ui__].concat(self.class.size_definitions.map { |name, process| name })
    end

    def value(format=:html, *args)
      sizes[:original].src
    end

    def set_value!(value, process = true)
      @sizes = nil
      super
    end

    def generate(output, media_file)
      return { :src => media_file } if media_file.is_a?(::String)#File.exist?(image_path)
      image = Processor.new(media_file)
      # Create a tempfile here that will be kept open for the duration of the block
      # this is used in #apply to hold a copy of the processed image data rather than
      # rely on the minimagick generated tempfiles which can get closed
      result = Tempfile.open("image_#{output}") do |tempfile|
        case output
        when :original
          image
        else
          process = self.class.size_definitions[output]
          image.apply(process, output, tempfile)
        end.serialize
      end
      # result.serialize
    end


    def export(user = nil)
      super(user).merge({
        :processed_value => processed_values
      })
    end

    self.register(:image, :photo)
  end
end

