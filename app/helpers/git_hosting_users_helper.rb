module GitHostingUsersHelper
  def user_settings_tabs
    tabs = super
    tabs << { name: 'keys', partial: 'gitolite_public_keys/view', label: :label_public_keys }
  end

  # Hacked render_api_custom_values to add plugin values to user api.
  # @NOTE: there is no solution for index.api, because @user is missing
  # @TODO
  def render_api_custom_values(custom_values, api)
    rc = super

    if @user.present?
      api.array :ssh_keys do
        @user.gitolite_public_keys.each do |key|
          api.ssh_key do
            api.id       key.id
            api.key_type key.key_type_as_string
            api.title    key.title
            api.key      key.key
          end
        end
      end
    end

    rc
  end
end
