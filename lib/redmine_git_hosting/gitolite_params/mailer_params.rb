module RedmineGitHosting
  module GitoliteParams
    class MailerParams

      include BaseParam

      attr_reader :namespace
      attr_reader :current_params
      attr_reader :current_mailer_params


      def initialize
        ## Namespace where to set params
        @namespace = 'multimailhook'

        ## Get current params
        @current_params        = get_git_config_params(@namespace)
        @current_mailer_params = get_mailer_params

        # Build hash of installed params
        @installed = {}
      end


      def installed?
        mailer_params.each do |param|
          next if current_mailer_params[param].empty?
          @installed[param] = (current_params[param] == current_mailer_params[param])
        end
        @installed
      end


      def install!
        mailer_params.each do |param|
          next if current_mailer_params[param].empty?
          @installed[param] = set_git_config_param(namespace, param, current_mailer_params[param])
        end
        @installed
      end


      private


        def mailer_params
          %w(mailer environment smtpauth smtpserver smtpport smtpuser smtppass)
        end


        def get_mailer_params
          params = {}
          params['environment'] = 'gitolite'
          params['mailer']      = mailer
          params['smtpauth']    = smtpauth_enabled?.to_s
          params['smtpserver']  = ActionMailer::Base.smtp_settings[:address].to_s
          params['smtpport']    = ActionMailer::Base.smtp_settings[:port].to_s
          params['smtpuser']    = ActionMailer::Base.smtp_settings[:user_name] || ''
          params['smtppass']    = ActionMailer::Base.smtp_settings[:password] || ''
          params
        end


        def mailer
          ActionMailer::Base.delivery_method == :smtp ? 'smtp' : 'sendmail'
        end


        def smtpauth_enabled?
          auth = ActionMailer::Base.smtp_settings[:authentication]
          auth != nil && auth != '' && auth != :none
        end

    end
  end
end
