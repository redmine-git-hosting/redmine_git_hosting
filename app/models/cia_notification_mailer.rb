require 'xmlrpc/client'

class CiaNotificationMailer < ActionMailer::Base
  unloadable

  helper :git_hosting
  include GitHostingHelper

  def notification(revision, branch)
    @subject = "DeliverXML"
    @recipients = ["cia@cia.vc"]
    @content_type = "text/xml"
    from "CIABOT-NOREPLY@#{ Setting['host_name'].match('localhost')? Setting['mail_from'].split('@')[-1] : Setting['host_name'] }"
    @sent_on = Time.now
    @body = render_message(
      "cia_notification.erb", :revision => revision, :branch => branch,
      :plugin => Redmine::Plugin.find('redmine_git_hosting')
     )
    GitHosting.logger.debug "---8<----8<--- CIA Notification Body ---8<----8<---\n#{body}---8<----8<--- CIA Notification Body ---8<----8<---"
    @headers = {
      "Message-ID" => "<#{revision.revision}.#{revision.author}@#{revision.project.name}>"
    }
  end

  # Overrides default deliver! method to first try to deliver the CIA notification
  # through RPC(3 seconds timeout). If failed, send it by email.
  def deliver!(mail = @mail)

    rpc_server = XMLRPC::Client.new(
      host="www.cia.vc", path="/RPC2", port=nil, proxy_host=nil,
      proxy_port=nil, user=nil, password=nil, use_ssl=false, timeout=3
    )

    begin
      ok, result = rpc_server.call2("hub.deliver", @body)
      if ok:
        GitHosting.logger.info "RPC Called. OK => #{ok}  Result => #{result}"
        return false
      end
      GitHosting.logger.info "Failed to post the RPC call: #{result}"
    rescue XMLRPC::FaultException => e
      GitHosting.logger.info "RPC Failed. Error => #{e}"
    rescue Errno::ECONNREFUSED => e
      GitHosting.logger.info "RPC Connection Refused. Error => #{e}"
    rescue SocketError => e
      GitHosting.logger.info "RPC Socket Error. Error => #{e}"
    rescue Exception => e
      GitHosting.logger.info "RPC Error. Error => #{e}"
    end

    GitHosting.logger.info "Delivering By Email"

    return false if (recipients.nil? || recipients.empty?) &&
      (cc.nil? || cc.empty?) &&
      (bcc.nil? || bcc.empty?)

    # Log errors when raise_delivery_errors is set to false, Rails does not
    raise_errors = self.class.raise_delivery_errors
    self.class.raise_delivery_errors = true
    begin
      return super(mail)
    rescue Exception => e
      if raise_errors
        raise e
      elsif mylogger
        GitHosting.logger.error "The following error occured while sending email notification: \"#{e.message}\". Check your configuration in config/configuration.yml."
      end
    ensure
      self.class.raise_delivery_errors = raise_errors
    end
  end

end
