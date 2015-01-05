module RedmineGitHosting::Cache
  class Adapter

    class << self

      def factory
        Database.new
      end

    end

  end
end
