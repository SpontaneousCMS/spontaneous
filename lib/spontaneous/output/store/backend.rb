module Spontaneous::Output::Store
  class Backend
    def initialize(options = {})
    end

    def store_static(revision, key, template, transaction = nil)
      store(revision, :static, key, template, transaction)
    end

    def store_protected(revision, key, template, transaction = nil)
      store(revision, :protected, key, template, transaction)
    end

    def store_dynamic(revision, key, template, transaction = nil)
      store(revision, :dynamic, key, template, transaction)
    end

    def store_asset(revision, key, template, transaction = nil)
      store(revision, :assets, key, template, transaction)
    end

    def load_static(revision, key)
      load(revision, :static, key, static: true)
    end

    def load_protected(revision, key)
      load(revision, :protected, key, static: false)
    end

    def load_dynamic(revision, key)
      load(revision, :dynamic, key, static: false)
    end

    def load_asset(revision, key)
      load(revision, :assets, key, static: true)
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

    def store(revision, partition, path, template, transaction)
      raise NotImplementedError
    end

    def load(revision, partition, path)
      raise NotImplementedError
    end
  end
end
