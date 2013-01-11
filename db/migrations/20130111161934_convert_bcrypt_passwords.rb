
Sequel.migration do
  up do
    scheme = Spontaneous::Crypt::Version::SHALegacy

    dataset = nil
    begin
      dataset = Spontaneous.database[:spontaneous_users]
    rescue
      # Test environment
      dataset = DB[:spontaneous_users]
    end

    dataset.each do |user|
      hash = scheme.create(user[:crypted_password], user[:salt])
      dataset.filter(:id => user[:id]).update(:crypted_password => hash)
    end

    drop_column :spontaneous_users, :salt
  end

  down do
    # There's no way to recover from the conversion -- the
    # hashed password is lost so all we can do is re-add the salt
    # column
    add_column :spontaneous_users, :salt
  end
end
