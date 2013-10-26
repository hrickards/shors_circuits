# See http://armoredcode.com/blog/crafting-an-authentication-subsystem-that-rocks-for-your-padrino-application-with-omniauth/
# and http://net.tutsplus.com/tutorials/ruby/how-to-use-omniauth-to-authenticate-your-users/
class User
  include MongoMapper::Document

  # key <name>, <type>
  key :name, String
  key :email, String
  key :uid, String

  many :authorizations

  timestamps!

  def add_provider(omniauth)
    unless self.authorizations.find_by_provider(omniauth["provider"])
      self.authorizations << Authorization.create(
        provider: omniauth["provider"],
        uid: omniauth["uid"]
      )
      self.save!
    end
  end

  def self.find_or_create(omniauth)
    auth = Authorization.find_by_provider_and_uid(
      omniauth["provider"], omniauth["uid"]
    )
    if auth
      user = auth.user
    else
      user = User.create_from_omniauth omniauth
    end

    user
  end

  def self.create_from_omniauth(omniauth)
    user = User.create(
      name: omniauth["info"]["name"],
      email: omniauth["info"]["email"],
      uid: omniauth["uid"]
    )
    user.add_provider(omniauth)

    user
  end

  def circuits
    Circuit.find_all_by_uid self.uid
  end

  def operators;
    Operator.find_all_by_uid self.uid
  end
end
