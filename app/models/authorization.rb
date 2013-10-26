# See http://armoredcode.com/blog/crafting-an-authentication-subsystem-that-rocks-for-your-padrino-application-with-omniauth/
# and http://net.tutsplus.com/tutorials/ruby/how-to-use-omniauth-to-authenticate-your-users/
class Authorization
  include MongoMapper::Document

  # key <name>, <type>
  key :provider, String
  key :uid, String

  belongs_to :user
end
