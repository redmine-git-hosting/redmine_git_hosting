module RedmineGitolite::HookManager

  class MailerParams < HookParam

    attr_reader :namespace
    attr_reader :current_params


    def initialize
      ## Namespace where to set params
      @namespace = 'multimailhook'

      ## Get current params
      @current_params = get_git_config_params(@namespace)
    end


    def installed?
      params = %w(mailer environment smtpauth smtpserver smtpport smtpuser smtppass)
      mailer_params = get_mailer_params

      installed = {}

      params.each do |param|
        if current_params[param] != mailer_params[param]
          installed[param] = set_git_config_param(namespace, param, mailer_params[param])
        else
          installed[param] = true
        end
      end

      return installed
    end


    private


      def get_mailer_params
        params = {}

        params['environment'] = 'gitolite'

        if ActionMailer::Base.delivery_method == :smtp
          params['mailer'] = 'smtp'
        else
          params['mailer'] = 'sendmail'
        end

        auth = ActionMailer::Base.smtp_settings[:authentication]

        if auth != nil && auth != '' && auth != :none
          params['smtpauth'] = 'true'
        else
          params['smtpauth'] = 'false'
        end

        params['smtpserver'] = ActionMailer::Base.smtp_settings[:address].to_s
        params['smtpport']   = ActionMailer::Base.smtp_settings[:port].to_s
        params['smtpuser']   = ActionMailer::Base.smtp_settings[:user_name] || ''
        params['smtppass']   = ActionMailer::Base.smtp_settings[:password] || ''

        params
      end

  end
end
