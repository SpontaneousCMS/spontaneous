
module Spontaneous
  class PageLock < Sequel::Model(:spontaneous_page_lock)
    class InvalidPage < Spontaneous::Error; end

    plugin :timestamps

    many_to_one :page, :class => "Spontaneous::Content", :key => :page_id
    many_to_one :content, :class => "Spontaneous::Content", :key => :content_id

    def self.lock_field(field)
      create(field_attributes(field).merge(
        :description => field.page_lock_description
      ))
    rescue InvalidPage
      nil
    end

    def self.unlock_field(field)
      field_dataset(field).delete
    rescue InvalidPage
      nil
    end

    def self.field_dataset(field)
      filter(field_attributes(field))
    end

    def self.field_attributes(field)
      owner = field.owner
      raise InvalidPage.new(field.id) unless owner.page
      { :content_id => owner.content_instance.id,
        :page_id    => owner.page.id,
        :field_id   => field.id }
    end

    def field=(field)
      self.field_id = field.id
    end

    def field
      @field ||= Spontaneous::Field.find(field_id)
    end
  end
end
