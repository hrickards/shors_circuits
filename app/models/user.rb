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

  def authenticated_with?(provider)
    not self.authorizations.detect { |auth| auth.provider == provider.to_s}.nil?
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

  def grouped_circuits(limit=5)
    # Get all of the current user's circuits
    gcircuits = self.circuits.group_by { |c| c.c_id }.to_a
    # For each circuit, show the last 5 iterations, and find the modified date
    gcircuits.map! do |cid, circuits|
      [
        cid,
        circuits.sort_by { |circuit| circuit.v_id }.last(limit),
        circuits.map { |circuit| circuit.updated_at }.sort.first
      ]
    end
    # Sort circuits by date, starting with most recent
    gcircuits.sort_by! { |cid, circuits, updated_at| updated_at }
    gcircuits.reverse!

    gcircuits
  end
end
