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

      @@gitolite_infos_cached = nil
      @@gitolite_info_stamp   = nil

      def gitolite_infos
        if !@@gitolite_infos_cached.nil? && (Time.new - @@gitolite_info_stamp <= 1)
          return @@gitolite_infos_cached
        end
        begin
          @@gitolite_infos_cached = ssh_shell('info')[0]
        rescue RedmineGitolite::GitHosting::GitHostingException => e
          logger.error { "Error while getting Gitolite version" }
          @@gitolite_infos_cached = ''
        end
        @@gitolite_info_stamp = Time.new
        return @@gitolite_infos_cached
      end


      def gitolite_version
        logger.debug { "Getting Gitolite version..." }
        find_version(gitolite_infos)
      end


      def gitolite_banner
        logger.debug { "Getting Gitolite banner..." }
        gitolite_infos
      end


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


      def gitolite_repository_count
        if gitolite_version == 3
          logger.debug { "Getting Gitolite physical repositories list..." }

          begin
            count = sudo_capture('gitolite', 'list-phy-repos').split("\n").length
          rescue RedmineGitolite::GitHosting::GitHostingException => e
            logger.error { "Error while getting Gitolite physical repositories list" }
            count = 0
          end

          return count
        else
          return 'This is Gitolite v2, not implemented...'
        end
      end

    end

  end
end
