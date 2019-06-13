module RedmineGitHosting
  class Auth
    def find(login, password)
      user = User.find_by_login(login)
      # Return if user not found
      return nil if user.nil?

      # Return user if password matches
      user if user.check_password?(password)
    end
  end
end
