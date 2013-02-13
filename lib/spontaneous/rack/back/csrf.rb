module Spontaneous::Rack::Back

  # Creates and inserts CSRF tokens into Rack env
  # If token is present then it validates it and adds the validation
  # status to the `env`. If it isn't present then one is created
  # passed into the `env` and the validation flag is unset
  #
  # This depends on the presences of an AccessKey in the `env`
  class CSRFHeader
    include Spontaneous::Rack::Constants

    def initialize(app)
      @app = app
    end

    def call(env)
      if (key = env[ACTIVE_KEY])
        token = env[CSRF_ENV]
        call!(env, key, token)
      else # Should never happen
        [401, {}, ["Unauthorised"]]
      end
    end

    def call!(env, key, token)
      valid = valid?(key, token)
      token ||= key.generate_csrf_token
      @app.call(env.merge(CSRF_VALID => valid, CSRF_TOKEN => token))
    end

    def valid?(key, token)
      key.csrf_token_valid?(token)
    end
  end

  # Provides CSRF verification for requests. Relies upon the Header
  # app to insert the validation step.
  class CSRFVerification
    include Spontaneous::Rack::Constants

    def initialize(app)
      @app = app
    end

    def call(env)
      return [401, {}, ["Unauthorised"]] unless env[CSRF_VALID]
      @app.call(env)
    end
  end
end
