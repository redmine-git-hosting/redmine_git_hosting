module RepositoryDeploymentCredentialsHelper

  def build_list_of_keys(user_keys, other_keys, disabled_keys)
    option_array = [[l(:label_deployment_credential_select_deploy_key), -1]]
    option_array += user_keys.map { |key| [keylabel(key), key.id] }

    if !other_keys.empty?
      option_array2 = other_keys.map { |key| [keylabel(key), key.id] }
      maxlen = (option_array + option_array2).map { |x| x.first.length }.max

      extra = ([maxlen - l(:select_other_keys).length - 2, 6].max) / 2
      option_array += [[('-' * extra) + ' ' + l(:select_other_keys) + ' ' + ('-' * extra), -2]]
      option_array += option_array2
    end

    options_for_select(option_array, selected: -1, disabled: [-2] + disabled_keys.map(&:id))
  end

end
