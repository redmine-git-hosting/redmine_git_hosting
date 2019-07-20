module GitHostingUsersHelper
  def user_settings_tabs
    tabs = super
    tabs << { name: 'keys', partial: 'gitolite_public_keys/view', label: :label_public_keys }
  end
end
