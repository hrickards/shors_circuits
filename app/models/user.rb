# See http://armoredcode.com/blog/crafting-an-authentication-subsystem-that-rocks-for-your-padrino-application-with-omniauth/
class User
  include MongoMapper::Document

  # key <name>, <type>
  key :uid, String
  key :name, String
  key :email, String

  timestamps!

  def self.new_from_omniauth(omniauth)
    user = User.new
    user.uid = omniauth["uid"]
    user.name = omniauth["info"]["name"]
    user.email = omniauth["info"]["email"]

    user.save!
    user
  end

  def circuits
    Circuit.find_all_by_uid self.uid
  end
end
