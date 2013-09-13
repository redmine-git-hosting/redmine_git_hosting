module GitolitePublicKeysHelper

  def gitolite_public_keys_status_options_for_select(user, selected)
    key_count_by_active = user.gitolite_public_keys.count(:group => 'active').to_hash
    options_for_select([[l(:label_all), nil],
          ["#{l(:status_active)} (#{key_count_by_active[true].to_i})", GitolitePublicKey::STATUS_ACTIVE],
          ["#{l(:status_locked)} (#{key_count_by_active[false].to_i})", GitolitePublicKey::STATUS_LOCKED]], selected)
  end


  def keylabel(key)
    if key.user == User.current
      "\"#{key.title}\""
    else
      "\"#{key.user.login}@#{key.title}\""
    end
  end


  def keylabel_text(key)
    if key.user == User.current
      "#{key.title}"
    else
      "#{key.user.login}@#{key.title}"
    end
  end


  def wrap_and_join(in_array, my_or = "or")
    my_array = in_array.map{|x| "\"#{x}\""}
    length = my_array.length
    return my_array if length < 2
    my_array[length-1] = my_or + " " + my_array[length-1]
    if length == 2
      my_array.join(' ')
    else
      my_array.join(', ')
    end
  end

end
