module GitolitableNotifications
  extend ActiveSupport::Concern

  def default_list
    ::GitNotifier.new(self).default_list
  end


  def mail_mapping
    ::GitNotifier.new(self).mail_mapping
  end

end
