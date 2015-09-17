module RedmineGitHosting
  class PluginAuthor

    attr_reader :author


    def initialize(author)
      @author = author
    end


    def name
      RedmineGitHosting::Utils::Git.author_name(author)
    end


    def email
      RedmineGitHosting::Utils::Git.author_email(author).downcase
    end

  end
end
