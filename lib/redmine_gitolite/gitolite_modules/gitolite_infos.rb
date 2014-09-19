module RedmineGitolite::GitoliteModules

  module GitoliteInfos

    ##########################
    #                        #
    #     GITOLITE INFOS     #
    #                        #
    ##########################

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def find_version(output)
        return 0 if output.blank?

        version = nil

        line = output.split("\n")[0]

        if line =~ /gitolite[ -]v?2./
          version = 2
        elsif line.include?('running gitolite3')
          version = 3
        else
          version = 0
        end

        return version
      end


      def gitolite_command
        if gitolite_version == 2
          gitolite_command = ['gl-setup']
        elsif gitolite_version == 3
          gitolite_command = ['gitolite', 'setup']
        else
          gitolite_command = nil
        end
        return gitolite_command
      end


      @@gitolite_version_cached = nil
      @@gitolite_version_stamp  = nil

      def gitolite_version
        if !@@gitolite_version_cached.nil? && (Time.new - @@gitolite_version_stamp <= 1)
          return @@gitolite_version_cached
        end

        logger.debug { "Getting Gitolite version..." }

        begin
          out, err, code = ssh_shell('info')
          @@gitolite_version_cached = find_version(out)
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while getting Gitolite version" }
          @@gitolite_version_cached = -1
        end

        @@gitolite_version_stamp = Time.new
        return @@gitolite_version_cached
      end


      @@gitolite_banner_cached = nil
      @@gitolite_banner_stamp  = nil

      def gitolite_banner
        if !@@gitolite_banner_cached.nil? && (Time.new - @@gitolite_banner_stamp <= 1)
          return @@gitolite_banner_cached
        end

        logger.debug { "Getting Gitolite banner..." }

        begin
          @@gitolite_banner_cached = ssh_shell('info')[0]
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while getting Gitolite banner" }
          @@gitolite_banner_cached = "Error : #{e.message}"
        end

        @@gitolite_banner_stamp = Time.new
        return @@gitolite_banner_cached
      end


      @@gitolite_repository_count_cached = nil
      @@gitolite_repository_count_stamp  = nil

      def gitolite_repository_count
        if gitolite_version == 3
          if !@@gitolite_repository_count_cached.nil? && (Time.new - @@gitolite_repository_count_stamp <= 1)
            return @@gitolite_repository_count_cached
          end

          logger.debug { "Getting Gitolite physical repositories list..." }

          begin
            @@gitolite_repository_count_cached = sudo_capture('gitolite', 'list-phy-repos').split("\n").length
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            logger.error { "Error while getting Gitolite physical repositories list" }
            @@gitolite_repository_count_cached = "Error : #{e.message}"
          end

          @@gitolite_repository_count_stamp = Time.new
          return @@gitolite_repository_count_cached
        else
          return @@gitolite_repository_count_cached = 'This is Gitolite v2, not implemented...'
        end
      end

    end

  end
end
