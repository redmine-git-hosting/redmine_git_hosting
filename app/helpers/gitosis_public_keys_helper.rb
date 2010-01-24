module GitosisPublicKeysHelper
  def gitosis_public_keys_status_options_for_select(user, selected)
    key_count_by_active = user.gitosis_public_keys.count(:group => 'active').to_hash
    options_for_select([[l(:label_all), nil], 
                        ["#{l(:status_active)} (#{key_count_by_active[true].to_i})", GitosisPublicKey::STATUS_ACTIVE],
                        ["#{l(:status_locked)} (#{key_count_by_active[false].to_i})", GitosisPublicKey::STATUS_LOCKED]], selected)
  end
  
end