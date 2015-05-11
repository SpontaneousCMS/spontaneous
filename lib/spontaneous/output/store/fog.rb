
require 'fog'
require 'thread'

module Spontaneous::Output::Store
  class Fog < Backend
    def initialize(config)
      @config = config
    end

    def start_revision(revision)
      file = bucket.files.create(key: test_store_key(revision), body: "Revision #{revision} #{Time.now}")
      file.destroy
    end

    def current_revision
      f = bucket.files.get(current_revision_key)
      return nil if f.nil?
      f.body.to_i
    end

    def revisions
      unserialize(bucket.files.get(revisions_key)) || []
    end

    def revision(revision)
      unserialize(bucket.files.get(revision_key(revision)))
    end

    def add_revision(revision, keys)
      upload_queue.join
      save_revisions(revisions.push(revision).uniq.sort)
      bucket.files.create(key: revision_key(revision), body: serialize(keys))
    end

    def activate_revision(revision)
      partitioned_revision(revision).each do |partition, key, path|
        case partition
        when :static, :assets # only static & asset files get copied
          activate_queue.enq([partition, key, path])
        end
      end

      activate_queue.join

      if revision.nil?
        bucket.files.new(key: current_revision_key).destroy
      else
        bucket.files.create(key: current_revision_key, body: revision.to_s)
      end
    end

    def delete_revision(revision)
      keys = revision(revision)
      keys.each do |key|
        bucket.files.new(key: key).destroy
      end
      bucket.files.new(key: revision_key(revision)).destroy
      existing_revisions = revisions
      existing_revisions.delete(revision)
      save_revisions(existing_revisions.uniq.sort)
    end

    def store(revision, partition, _path, template, transaction)
      path = safe_path(_path)
      tmp.store(revision, partition, path, template, nil)
      key = key(revision, partition, path)
      upload_queue.enq([[revision, partition, path], key])
      transaction.push(key) if transaction
    end

    def join
      upload_queue.join
      activate_queue.join
    end

    protected

    def upload_queue
      @upload_queue ||= ParallelAction.new(4) do |keys, n|
        local, remote = keys
        body = tmp.load(*local, static: true)
        bucket.files.create(key: remote, body: body)
      end
    end

    def activate_queue
      # There's almost no bandwidth needed for this operation, so we are mostly
      # just waiting for s3 to respond -- can then usefully ramp up the
      # parallelism
      @activate_queue ||= ParallelAction.new(12) do |file, n|
        partition, key, path = file
        case partition
        when :static
          activate_static(key, path)
        when :assets
          activate_asset(key, path)
        end
      end
    end

    def bucket_name
      @config[:bucket]
    end

    def bucket
      @bucket ||= connection.directories.get(bucket_name)
    end

    def connection
      @connection ||= ::Fog::Storage.new(@config[:connection])
    end

    def partitioned_revision(r)
      keys = revision(r)
      return [] if keys.nil?
      keys.map { |key|
        _, namespace, path = key.split(':')
        _, _revision, partition = namespace.split('/')
        [partition.to_sym, key, path]
      }
    end

    # TODO: remove duplication between here & CacheableFile
    ONE_YEAR = (365.25*24*3600).ceil
    ONE_MINUTE = 60

    # copy to the root namespace with public flag & a short/zero expiry
    def activate_static(key, path)
      activate_file(key, path, {cache_control: "public, max-age=#{ONE_MINUTE}"})
    end

    # copy to the root namespace with public flag & a 1 year expiry
    def activate_asset(key, path)
      activate_file(key, asset_path(path), {cache_control: "public, max-age=#{ONE_YEAR}"})
    end

    def activate_file(key, path, headers)
      dest_path = activated_path(path)
      bucket.files.get(key).copy(bucket_name, dest_path).tap do |file|
        file.metadata = { public: true }.merge(add_charset(file, headers))
        file.save
      end
    end

    def activated_path(path)
      return index_document if path == '/index.html'
      remove_leading_slash(translate_path(path))
    end

    def remove_leading_slash(path)
      path.sub(/^\//, '')
    end

    def translate_path(path)
      ext = ::File.extname(path)
      return path unless ext == '.html'.freeze
      path.gsub(/\.html$/, '')
    end

    def index_document
      @config.fetch(:index_document, 'index.html')
    end

    # TODO: use unified configurable asset prefix
    def asset_path(path)
      ::File.join('/assets', path)
    end

    def add_charset(file, headers)
      case (type = file.content_type)
      when 'text/html'
        headers.merge(content_type: "#{type};charset=utf-8")
      else
        headers
      end
    end

    def save_revisions(revisions)
      bucket.files.create(key: revisions_key, body: serialize(revisions.sort))
    end

    def test_store_key(revision)
      ":revisions/test-#{revision}"
    end

    def revision_key(revision)
      ":revisions/#{revision}"
    end

    def current_revision_key
      ":revisions/current".freeze
    end

    def revisions_key
      ":revisions/list".freeze
    end

    def key(revision, partition, path)
      [":revision", pad_revision_number(revision), "#{partition}:#{path}"].join('/')
    end

    def safe_path(path)
      return ::File.join('/', index_document) if path == '/'
      path
    end

    def pad_revision_number(r)
      r.to_s.rjust(5, '0')
    end

    def serialize(obj)
      Spontaneous::JSON.encode(obj)
    end

    def unserialize(obj)
      return nil if obj.nil?
      Spontaneous::JSON.parse(obj.body)
    end

    def tmpdir
      @tmpdir ||= Dir.mktmpdir
    end

    def tmp
      @tmp ||= File.new(root: tmpdir)
    end
  end

  class ParallelAction
    def initialize(thread_count = 4, &block)
      @thread_count = thread_count
      @action = block
      @running = false
    end

    def queue
      @queue ||= Queue.new
    end

    def enq(value)
      start!
      queue.enq(value)
    end

    def start!
      return if @running
      @running = true
      @threads = @thread_count.times.map { |n|
        Thread.new do
          while (value = queue.deq) != :stop
            @action.call(value, n)
          end
        end
      }
    end

    def join
      return unless @running
      @threads.each do
        queue.enq(:stop)
      end
      @threads.each(&:join)
    end
  end
end
