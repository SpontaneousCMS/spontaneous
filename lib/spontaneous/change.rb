# encoding: UTF-8

module Spontaneous
  class Change < Sequel::Model(:changes)
    class << self
      alias_method :sequel_plugin, :plugin
    end

    sequel_plugin :yajl_serialization, :modified_list

    @@instance = nil

    class << self
      def record
        entry_point = @@instance.nil?
        @@instance ||= self.new(:modified_list => [])
        yield if block_given?
      ensure
        if entry_point and !@@instance.modified_list.empty?
          @@instance.save
        end
        @@instance = nil if entry_point
      end

      def recording?
        !@@instance.nil?
      end

      def push(page)
        if @@instance
          @@instance.push(page)
        end
      end

      def outstanding
        dependencies = dependency_map
        dependencies.map { |d| Spontaneous::Collections::ChangeSet.new(d) }
      end

      def dependency_map
        grouped_changes = self.valid.map { |c| [c] }
        begin
          modified = false
          grouped_changes.each_with_index do |inner, i|
            inner_ids = inner.map { |c| c.modified_list }.flatten
            grouped_changes[(i+1)..-1].each_with_index do |outer, j|
              outer_ids = outer.map { |c| c.modified_list }.flatten
              unless (inner_ids & outer_ids).empty?
                modified = true
                grouped_changes.delete(outer)
                grouped_changes[i] += outer
              end
            end
          end
        end while modified

        grouped_changes
      end

      def valid
        invalid, valid = self.all.partition { |change| change.modified.empty? }
        self.filter(:id => invalid.map { |change| change.id }).delete
        valid
      end
    end


    def after_initialize
      super
      self.modified_list ||= []
    end

    def push(page)
      self.modified_list << page.id
    end

    def before_update
      self.modified_list.uniq!
    end

    def modified
      @modified ||= modified_list.map { |id| Content[id] }.compact
    end

    alias_method :pages, :modified

    def &(change)
      self.modified_list & change.modified_list
    end

    def to_hash
      {
        :id => self.id,
        :created_at => self.created_at.to_s,
        :page_ids => modified_list
      }
    end
  end
end
