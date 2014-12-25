module GitHostingHelper

  def checked_image2(checked=true)
    if checked
      image_tag 'toggle_check.png'
    else
      image_tag 'exclamation.png'
    end
  end


  def label_with_icon(label, icon, inverse = false, fixed = false)
    css_class = [ "fa", "fa-lg" ]

    css_class.push(icon)

    if inverse
      css_class.push("fa-inverse")
    end

    if fixed
      css_class.push("fa-fw")
      css_class.delete("fa-lg")
    end

    css_class = css_class.join(" ")
    content = content_tag(:i, "", class: css_class) + label

    return content.html_safe
  end


  def user_allowed_to(permission, project)
    if project.active?
      return User.current.allowed_to?(permission, project)
    else
      return User.current.allowed_to?(permission, nil, global: true)
    end
  end


  def plugin_asset_link(plugin_name, asset_name)
    File.join(Redmine::Utils.relative_url_root, 'plugin_assets', plugin_name, 'images', asset_name)
  end

end
