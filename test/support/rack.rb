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

  alias_method :auth_del, :auth_delete

  def auth_patch(path, params={}, env={})
    patch(path, params, csrf_header(env))
  end

  def csrf_header(env)
    token = api_key.generate_csrf_token
    env.merge(Spontaneous::Rack::CSRF_ENV => token)
  end

  def api_key
    # Override in test suites
  end

  def login_user(user, params={})
    post "/@spontaneous/login", {"user[login]" => user.login, "user[password]" => user.password}.merge(params)
    key_id  = rack_mock_session.cookie_jar[Spontaneous::Rack::AUTH_COOKIE]
    @user   = user
    @key    = Spontaneous::Permissions::AccessKey.authenticate(key_id)
    [@user, @key]
  end
end
