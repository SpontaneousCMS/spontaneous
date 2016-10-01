require 'open-uri'

module Spontaneous
  module Cli
    class Fields < ::Thor
      include Spontaneous::Cli::TaskUtils
      include ::Simultaneous::Task

      namespace :fields

      desc "update", "Performs asynchronous updates on provided fields"
      method_option :fields, type: :array, desc: "List of field IDs to update"
      def update(*args)
        update_fields
      end

      desc "reprocess", "Re-process the given image fields. Fields should be defined as a space-separated list of TypeName@field_name entries"
      method_option :fields, type: :array, desk: "List of field IDs to reprocess"
      def reprocess(*args)
        reprocess_fields
      end

      private

      def update_fields
        prepare! :update, :console
        site = Spontaneous::Site.instance
        fields = Spontaneous::Field.find(site.model, *options.fields)
        updater = Spontaneous::Field::Update::Immediate.new(site, fields)
        updater.run
        send_completion_event(updater)
      end

      def send_completion_event(updater)
        unlocked_pages = updater.pages.reject { |p| p.locked_for_update? }
        simultaneous_event('page_lock_status', unlocked_pages.map(&:id).to_json)
      end

      def reprocess_fields
        prepare! :reprocess, :console
        site = Spontaneous::Site.instance
        fields = lookup_fields(options.fields)
        fields.each do |type, field_name|
          instances = type.all
          instances.each_with_index do |instance, n|
            puts "===> #{type}/#{instance.id}  (#{n}/#{instances.length})"
            reprocess_field(instance, field_name, site)
          end
        end
      end

      def lookup_fields(field_list)
        field_list
          .map { |d| d.split('@') }
          .map { |type_name, field_name| [type_name.constantize, field_name.to_sym]  }
      end

      def reprocess_field(content, field_name, site)
        field = content.fields[field_name]
        url = field.original.url
        return if url.blank?
        puts " --> original: #{ url }"
        open(url) do |original|
          filename, _ = field.file_info
          Tempfile.open(["#{content.id}-#{field_name}", ::File.extname(filename)]) do |file|
            # Copy to new tempfile to get control over name & path of local tempfile
            IO.copy_stream(original, file)
            reprocess_field_original(content, field, file, site)
          end
        end
      rescue Errno::ENOENT
        puts "Failed to download #{content.class.name} id #{content.id}: #{ url }"
      end

      def reprocess_field_original(content, field, original, site)
        values = field.processed_values
        filename = field.original_filename
        digest = field.file_hash.presence || field.file_digest(original)
        field.outputs.reject { |n| n == :original }.each do |output|
          print " --> size :#{output} ... "
          media_file = site.file(content, filename, digest, field.storage_headers(field.mimetype.to_s, filename)).clone(original)
          values[output] = field.generate(output, media_file, site)
          puts values[output][:src]
        end
        field.send :processed_values=, values
        field.save
        content.save
      end
    end
  end
end

