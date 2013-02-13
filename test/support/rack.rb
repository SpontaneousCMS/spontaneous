require 'rack/test'

module RackTestMethods
  include ::Rack::Test::Methods
  include Spontaneous::Rack::Constants

  def auth_post(path, params={}, env={})
    post(path, params, csrf_header(env))
  end

  def auth_get(path, params={}, env={})
    get(path, params, csrf_header(env))
  end

  def auth_put(path, params={}, env={})
    put(path, params, csrf_header(env))
  end

  def auth_delete(path, params={}, env={})
    delete(path, params, csrf_header(env))
  end

  def auth_patch(path, params={}, env={})
    patch(path, params, csrf_header(env))
  end

  def csrf_header(env)
    env.merge(Spontaneous::Rack::CSRF_ENV => api_key.generate_csrf_token)
  end

  def api_key
    # Override in test suites
  end
end
