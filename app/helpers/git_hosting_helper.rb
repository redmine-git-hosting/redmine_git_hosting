module GitHostingHelper

  def checked_image2(checked = true)
    if checked
      image_tag 'toggle_check.png'
    else
      image_tag 'exclamation.png'
    end
  end


  def label_with_icon(label, icon, opts = {})
    inverse = opts.delete(:inverse){ false }
    fixed   = opts.delete(:fixed){ false }

    css_class = [ 'fa', 'fa-lg' ]
    css_class.push(icon)
    css_class.push('fa-inverse') if inverse
    css_class.push('fa-fw') if fixed
    css_class.delete('fa-lg') if fixed

    klass = [opts.delete(:class), css_class].flatten.compact
    content_tag(:i, '', class: klass) + label
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
