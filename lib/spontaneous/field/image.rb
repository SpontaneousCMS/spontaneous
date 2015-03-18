# encoding: UTF-8

require 'tempfile'
require 'delegate'

module Spontaneous::Field
  class Image < File
    autoload :Size, 'spontaneous/field/image/size'

    include Spontaneous::Media::Image::Renderable

    has_editor

    def self.accepts
      %w{image/(png|jpeg|gif)}
    end

    def self.size(name, options = {}, &process)
      self.sizes[name.to_sym] = [options, process]
      unless method_defined?(name)
        class_eval "def #{name}(*args); sizes[:#{name}]; end"
      end
    end

    def self.sizes
      size_definitions
    end

    def self.validate_sizes(sizes)
      sizes
    end

    def self.size_definitions
      @size_definitions ||= superclass.respond_to?(:size_definitions) ? superclass.size_definitions.dup : default_size_definitions
    end

    def self.default_size_definitions
      { :original => original_size, :__ui__ => ui_preview_size }
    end

    def self.original_size
      [ {} ]
    end

    def self.ui_preview_size
      [ {}, proc { width 300 } ]
    end

    def self.default_attributes
      @default_attributes ||= {}
    end

    def self.default_attributes=(default_attributes = {})
      @default_attributes = default_attributes
    end

    def image?
      true
    end

    def blank?
      original.blank?
    end

    def sizes
      @sizes ||= Hash.new { |hash, key|
        hash[key] = S::Media::Image::Attributes.new(site, processed_values[key])
      }
    end

    # value used to show conflicts between the current value and the value they're attempting to enter
    def conflicted_value
      value
    end

    # I want to merge the file info available in the media file
    # with the image details (width, height etc)
    def serialize_pending_file(file)
      attrs = file.serialize
      url   = attrs.delete(:url)
      image = Spontaneous::Media::Image.new(file.path)
      attrs.merge(image.serialize).merge(super)
    end

    def page_lock_description
      "Processing image '#{pending_value[:value][:filename]}'"
    end

    # original is special and should always be defined
    def original
      @original ||= sizes[:original]
    end

    def width
      original.width || 0
    end

    def height
      original.height || 0
    end

    def filesize
      original.filesize || 0
    end

    def src
      original.src
    end

    def url
      original.url
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

    alias_method :processed_value, :value

    def set_value!(value, process = true, site = nil)
      @sizes = nil
      super
    end

    def generate(name, media_file, site)
      return { :src => media_file } if media_file.is_a?(::String)
      options, process = self.class.size_definitions[name]
      size = Size.new(media_file, name, options, process)
      size.generate
    end


    def export(user = nil)
      processed = Hash[outputs.map { |size|
        [size, sizes[size].export(user)]
      }]
      processed.update(__pending__: pending_value) if has_pending_value?
      super(user).merge({
        processed_value: processed
      })
    end

    self.register(:image, :photo)
  end
end
