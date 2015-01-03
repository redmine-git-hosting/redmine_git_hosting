module RedmineGitHosting
  module Utils
    include Utils::Exec
    include Utils::Git
    include Utils::Http
    include Utils::Password
    include Utils::Ssh
  end
end
