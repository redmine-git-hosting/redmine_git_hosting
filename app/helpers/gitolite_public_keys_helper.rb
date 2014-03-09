module GitolitePublicKeysHelper

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

end
