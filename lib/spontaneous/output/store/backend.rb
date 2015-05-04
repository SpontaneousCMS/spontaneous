module Spontaneous::Output::Store
  class Backend
    unless defined?(STATIC_PATH)
      STATIC_PATH, PROTECTED_PATH, DYNAMIC_PATH = %w(static protected dynamic).map(&:freeze)
    end

    def initialize(options = {})
      @asset_prefix = make_absolute_path options.fetch(:assets_prefix, '/assets')
    end

    def store_static(revision, key, template, transaction = nil)
      store(revision, STATIC_PATH, key, template, transaction)
    end

    def store_protected(revision, key, template, transaction = nil)
      store(revision, PROTECTED_PATH, key, template, transaction)
    end

    def store_dynamic(revision, key, template, transaction = nil)
      store(revision, DYNAMIC_PATH, key, template, transaction)
    end

    # Assets are a special class for writing, but not for reading.
    #
    # For writing we want each specific backend implementation to be able to
    # handle them separately for adding of far-future expiry headers for
    # example, but for reading assets should behave exactly as static files.
    def store_asset(revision, key, template, transaction = nil)
      store(revision, STATIC_PATH, prefix_asset(key), template, transaction)
    end

    def load_static(revision, key)
      load(revision, STATIC_PATH, key)
    end

    def load_protected(revision, key)
      load(revision, PROTECTED_PATH, key)
    end

    def load_dynamic(revision, key)
      load(revision, DYNAMIC_PATH, key)
    end

    def output_key(output, dynamic = false)
      path = output.page.path
      ext  = output.extension(dynamic)
      case path
      when Spontaneous::SLASH
        "/index#{ext}"
      else
        "#{path}#{ext}"
      end
    end

    protected

    def prefix_asset(key)
      ::File.join(@asset_prefix, key)
    end

    # File::join is clever enough to squash double slashes so this will always
    # result in '/path' even if path begins with '/'
    def make_absolute_path(path)
      ::File.join("/", path)
    end

    def store(revision, partition, path, template, transaction)
      raise NotImplementedError
    end

    def load(revision, partition, path)
      raise NotImplementedError
    end
  end
end
