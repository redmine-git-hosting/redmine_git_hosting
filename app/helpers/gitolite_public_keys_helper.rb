module GitolitePublicKeysHelper
  def gitolite_public_keys_status_options_for_select(user, selected)
    key_count_by_active = user.gitolite_public_keys.count(:group => 'active').to_hash
    options_for_select([[l(:label_all), nil],
                        ["#{l(:status_active)} (#{key_count_by_active[true].to_i})", GitolitePublicKey::STATUS_ACTIVE],
                        ["#{l(:status_locked)} (#{key_count_by_active[false].to_i})", GitolitePublicKey::STATUS_LOCKED]], selected)
  end

end