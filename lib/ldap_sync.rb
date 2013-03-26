# Class for synchronizing Nine LDAP data into the UZ DB
class LdapSync
  class << self

    def all
      LdapSync::Users.sync
      LdapSync::Teams.sync
      LdapSync::Links.sync
    end

  end
end
