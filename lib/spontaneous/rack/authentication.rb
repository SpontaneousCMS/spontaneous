# encoding: UTF-8

require 'rack'

module Spontaneous::Rack
  module Authentication

    def requires_authentication!(options = {})
      first_level_exceptions = (options[:except_all] || []).concat(["#{NAMESPACE}/login", "#{NAMESPACE}/reauthenticate"] )
      second_level_exceptions = (options[:except_key] || [])
      before {
        unless first_level_exceptions.any? { |e| e === request.path }
          ignore_key = second_level_exceptions.any? { |e| e === request.path }
          valid_key = ignore_key || Spontaneous::Permissions::AccessKey.valid?(params[KEY_PARAM], user)
          show_login_page( :login => '' ) unless (user and valid_key)
        end
      }
    end
  end
end
