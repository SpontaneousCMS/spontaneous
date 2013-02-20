module Spontaneous::Rack::Back
  class UserAdmin < Base
    User = Spontaneous::Permissions::User unless defined?(User)

    def with_account
      User.db.transaction do
        account = User.for_update.first(:id => params[:user_id])
        halt 403 unless user.level >= account.level
        yield account
      end
    end

    def load_level
      attr = params[:user]
      level_name = attr.delete(:level) || attr.delete("level")
      return nil if level_name.blank?
      level = Spontaneous::Permissions[level_name]
      halt 403 unless user.level >= level
      level
    end

    before {
      halt 403 unless user.admin?
    }

    get "/" do
      json User.export(user)
    end

    post "/" do
      level   = load_level
      account = User.new params[:user]
      if account.save
        account.update(:level => level)
        json User.export_user(account)
      else
        status 422
        json account.errors#.full_messages
      end
    end

    put "/:user_id" do
      with_account do |account|
        level = load_level
        account.update_fields(params[:user], [:login, :name, :email])
        if account.save
          account.update(:level => level) if level
          json User.export_user(account)
        else
          status 422
          json account.errors#.full_messages
        end
      end
    end

    delete "/:user_id" do
      with_account do |account|
        account.destroy
        200
      end
    end

    put "/password/:user_id" do
      with_account do |account|
        account.password = params[:password]
        if account.save
          # TODO: changing the password should log the user out?
          200
        else
          status 422
          json account.errors#.full_messages
        end
      end
    end

    delete "/keys/:user_id" do
      with_account do |account|
        account.clear_access_keys!
        200
      end
    end

    put "/disable/:user_id" do
      with_account do |account|
        account.disable!
        200
      end
    end

    put "/enable/:user_id" do
      with_account do |account|
        account.enable!
        200
      end
    end
  end
end
