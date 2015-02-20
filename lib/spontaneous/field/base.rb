module Spontaneous
  module Field
    class Base
      module ClassMethods
        def has_editor(js_class = ui_class)
          define_singleton_method(:editor_class) { js_class }
        end

        def register(*labels)
          labels = self.labels if labels.empty?
          # logger.debug("Registering #{self} as #{labels.join(", ")}")
          Field.register(self, *labels)
          self
        end

        def labels
          [self.name.demodulize.gsub(/Field$/, '').underscore]
        end

        def inherited(subclass, real_caller = nil)
          if self.respond_to?(:editor_class)
            editor_class = self.editor_class
            subclass.singleton_class.send(:define_method, :editor_class) do
              editor_class
            end
          end
        end

        def prototype=(prototype)
          @prototype = prototype
        end

        def prototype
          @prototype
        end

        def accepts
          %w(text/.+)
        end

        def accepts?(mime_type)
          accepts.find do |pattern|
            Regexp.new(pattern).match(mime_type)
          end
        end

        def default_options
          {}
        end

        # Provides the ability for specific field types to customize the schema values
        # they return to the UI
        def export(user)
          {}
        end
      end

      extend ClassMethods
      include Spontaneous::Model::Core::ContentHash::FieldMethods

      attr_accessor :owner, :name, :unprocessed_value, :template_params, :version
      attr_accessor :prototype


      def initialize(params={}, default_values=true)
        @default_values = default_values
        @processed_values = {}
        deserialize(params, default_values)
        @values = nil
      end

      def processed_values
        @values ||= processed_values_with_fallback
      end

      alias_method :values, :processed_values

      ValueHash = Spontaneous::Collections::HashWithFallback

      def processed_values_with_fallback
        return @processed_values if owner.nil? || prototype.fallback.nil?
        fallback = owner.fields[prototype.fallback]
        if fallback.nil?
          logger.warn("Missing field '#{prototype.fallback}' specified as fallback for field #{owner.class}::#{name}")
          return @processed_values
        end
        test     = proc { |val| self.blank? }
        ValueHash.new(fallback, test).update(@processed_values)
      end

      def [](key)
        processed_values[key]
      end

      def id
        [owner.id, schema_id].join("/")
      end

      # This is used exclusively to compute the filename/path of
      # temp files.
      #
      # To avoid creating a deep hierarchy under /media/tmp
      # which would be hard to cleanup we replace all dir separators
      # with underscores.
      #
      # The timestamp is added because otherwise serial modifications
      # to the same field might overwrite the value (though this is
      # unlikely)
      def media_id
        ids = [owner.id, schema_id, timestamp]
        ids.join("_").gsub(/\//, "_")
      end

      def writable?(user)
        owner.field_writable?(user, name)
      end

      # If a field type needs to do some long running processing
      # then it should declare itself as asynchronous so as not to tie up
      # the CMS process.
      def asynchronous?
        false
      end

      def pending_value=(value)
        set_pending_value(value, Spontaneous::Site.instance)
      end

      def set_pending_value(value, site)
        values[:__pending__] = {
          :value => value,
          :version => version + 1,
          :timestamp => timestamp
        }
      end

      # A timestamp value consistent for a particular field instance
      #
      # This is used to solve conflicts for async updates and to
      # tag a tempfile to a particular pending value.
      def timestamp
        @timestamp ||= Spontaneous::Field.timestamp
      end

      def pending_value
        values[:__pending__]
      end

      def has_pending_value?
        values.key?(:__pending__) && values[:__pending__].key?(:value)
      end

      def clear_pending_value
        values.delete(:__pending__)
      end

      def process_pending_value(site = Spontaneous::Site.instance)
        if (pending = process_pending_value!(site))
          cleanup_pending_value!(pending)
        end
        save
      end

      def process_pending_value!(site)
        if has_pending_value?
          pending = pending_value
          @previous_values = values.dup
          set_value!(pending_value[:value], true, site)
          pending
        end
      end

      # Ensures that this update can still run
      def invalid_update?
        return true if reload.nil?
        false
      end

      # Ensures that the pending value we have hasn't been superceded by
      # a later one.
      def conflicted_update?
        return false if is_valid_pending_value?
        self.processed_values = @previous_values
        true
      end

      # Reloads the field and compares the timestamps -- if our timestamp
      # is the same or greater than the reloaded value then we are the
      # most up-to-date update available. If not then we're not and
      # should abort.
      def is_valid_pending_value?
        return true if @previous_values.nil?
        reloaded = reload
        pending = @previous_values[:__pending__] || {}
        p1 = pending[:timestamp] || 0
        p2 = (reloaded.pending_value || {})[:timestamp] || 0
        if p1 >= p2
          true
        else
          @previous_values = reloaded.values
          false
        end
      end

      def cleanup_pending_value!(pending)
        clear_pending_value
        if pending && (v = pending[:value]) && v.is_a?(Hash)
          if (tempfile = v[:tempfile]) && ::File.exist?(tempfile)
            FileUtils.rm_r(::File.dirname(tempfile))
          end
        end
      end

      def reload
        owner.model.scope! do
          Spontaneous::Field.find(owner.model, id)
        end
      end

      # Called by Field::Update before launching the background
      # task that updates the field values.
      def before_asynchronous_update
      end

      def page_lock_description
        "Updating to new value"
      end

      def outputs
        [:html, :plain]
      end

      def process_value(value, site)
        @modified = (@initial_value != value)
        increment_version if @modified
        self.processed_values = generate_outputs(@unprocessed_value, site)
      end

      def set_value(v, process = true)
        set_value!(v, process, Spontaneous::Site.instance)
        save
      end

      def set_value!(v, process = true, site = nil)
        set_unprocessed_value(v)
        process_value(v, site) if process
      end

      def modified!
        owner.field_modified!(self) if owner
      end

      def increment_version
        self.version += 1
      end

      def version
        @version ||= 0
      end

      def pending_version
        return version unless has_pending_value?
        pending_value[:version]
      end

      def matches_version?(v)
        (version != v) && (pending_version != v)
      end

      # value used to show conflicts between the current value and the value they're attempting to enter
      def conflicted_value
        unprocessed_value
      end

      def generate_outputs(value, site)
        values = {}
        value = preprocess(value, site)
        outputs.each do |output|
          process_method = "generate_#{output}"
          values[output] = \
            if respond_to?(process_method)
              send(process_method, value, site)
            else
              generate(output, value, site)
            end
        end
        values
      end

      # should be overwritten in subclasses that actually do something
      # with the field value
      def preprocess(value, site)
        value
      end

      HTML_ESCAPE_TABLE = {
        '&' => '&amp;'
      }

      def escape_html(value)
        value.to_s.gsub(%r{[#{HTML_ESCAPE_TABLE.keys.join}]}) { |s| HTML_ESCAPE_TABLE[s] }
      end

      def generate(output, value, site)
        value
      end

      # attr_accessor :values

      # override this to return custom values derived from (un)processed_value
      # alias_method :value, :processed_value
      def value(format=:html)
        format = format.to_sym
        return unprocessed_value unless processed_values.key?(format)
        processed_values[format]
      end

      alias_method :processed_value, :value

      def image?
        false
      end

      def indexable_value
        unprocessed_value
      end

      def to_s(format = :html)
        value(format).to_s
      end

      def render(format = :html, locals = {}, *args)
        value(format)
      end

      alias_method :render_inline, :render

      def render_using(renderer, format = :html, locals = {}, *args)
        render(format, locals)
      end

      alias_method :render_inline_using, :render_using

      def to_html(locals = {})
        value(:html)
      end

      def to_pdf(*args)
        render(:pdf, *args)
      end

      def value=(value)
        self.set_value value, true
      end

      alias_method :unprocessed_value=, :value=

      def save
        owner.field_modified!(self) if owner
      end

      def mark_unmodified
        @modified = false
      end

      def modified?
        @modified || false
      end

      def schema_id
        self.prototype.schema_id
      end


      def schema_name
        self.prototype.schema_name
      end

      def schema_owner
        self.prototype.owner
      end

      def site
        owner.try(:site)
      end

      def owner_sid
        schema_owner.schema_id
      end

      def serialize_db
        S::Field.serialize_field(self)
      end

      # def start_inline_edit_marker
      #   "spontaneous:previewedit:start:field id:#{owner.id} name:#{self.name}"
      # end
      # def end_inline_edit_marker
      #   "spontaneous:previewedit:end:field id:#{owner.id} name:#{self.name}"
      # end

      def export(user)
        {
        :name => name.to_s,
        :id => schema_id.to_s,
        :unprocessed_value => unprocessed_value,
        :processed_value => ui_preview_value,
        :version => version
        }
      end

      def ui_preview_value
        value(:html)
      end

      def inspect
        %(#<#{self.class.name}:#{self.object_id} #{self.serialize_db.inspect}>)
      end

      def blank?
        unprocessed_value.blank?
      end

      alias_method :empty?, :blank?


      def or(field)
        return field if self.blank?
        self
      end

      alias_method :'/', :or
      alias_method :'|', :or

      def versions
        owner.field_versions(self)
      end

      def previous_version
        versions.first
      end

      def create_version
        Spontaneous::Field::FieldVersion.create(
          :content_id => owner.id,
          :field_sid => self.schema_id.to_s,
          :version => version,
          :value => @initial_value,
          :user => owner.current_editor)
        mark_unmodified
      end

      def <=>(o)
        unprocessed_value <=> o.unprocessed_value
      end

      def ==(o)
        eql?(o)
      end

      def eql?(o)
        super || (o.class == self.class &&
                  o.id == id &&
                  o.unprocessed_value == unprocessed_value &&
                  o.values == values)
      end

      def hash
        id.hash
      end

      protected

      def deserialize(params={}, default_values=true)
        data = params.dup
        unprocessed_value = data.delete(:unprocessed_value) || ""
        processed_values  = data.delete(:processed_values)  || {}
        set_unprocessed_value(unprocessed_value)
        @processed_values = processed_values
        set_value(unprocessed_value, default_values)
        data.each do |property, value|
          setter = "#{property}="
          self.send(setter, value) if respond_to?(setter)
        end
      end

      def processed_values=(values)
        @values = nil
        @processed_values = values
      end

      def set_unprocessed_value(new_value, preprocessed = false)
        # initial_value should only be set once so that it can act as a test for field modification
        @initial_value ||= new_value
        @unprocessed_value = new_value
      end

      def method_missing(method, *args)
        if outputs.include?(method)
          value(method)
        else
          super
        end
      end
    end
  end
end
