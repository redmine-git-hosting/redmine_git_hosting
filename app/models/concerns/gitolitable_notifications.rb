module GitolitableNotifications
  extend ActiveSupport::Concern

  def notifier
    @notifier ||= ::GitNotifier.new(self)
  end


  def default_list
    notifier.default_list
  end


  def mail_mapping
    notifier.mail_mapping
  end


  def mailing_list
    notifier.mailing_list
  end


  def sender_address
    notifier.sender_address
  end


  def email_prefix
    notifier.email_prefix
  end

end
