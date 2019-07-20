module BootstrapKitHelper
  include BootstrapKit::AjaxHelper
  include BootstrapKit::PresenterHelper

  def bootstrap_load_base
    stylesheet_link_tag('bootstrap_custom', plugin: 'redmine_git_hosting') +
      bs_include_css('bootstrap_custom')
  end

  def bootstrap_load_module(bs_module)
    method = "load_bs_module_#{bs_module}"
    send(method)
  end

  def checked_image_with_exclamation(checked = true)
    checked ? image_tag('toggle_check.png') : image_tag('exclamation.png')
  end

  private

  def bs_include_js(js)
    javascript_include_tag "bootstrap/#{js}", plugin: 'redmine_git_hosting'
  end

  def bs_include_css(css)
    stylesheet_link_tag "bootstrap/#{css}", plugin: 'redmine_git_hosting'
  end

  def load_bs_module_alerts
    bs_include_js('bootstrap_alert') +
      bs_include_js('bootstrap_alert_helper') +
      bs_include_js('bootstrap_transitions') +
      bs_include_css('bootstrap_alert') +
      bs_include_css('bootstrap_animations') +
      bs_include_css('bootstrap_close')
  end

  def load_bs_module_label
    bs_include_css('bootstrap_label')
  end

  def load_bs_module_modals
    bs_include_js('bootstrap_modal')
  end

  def load_bs_module_sortable
    bs_include_js('bootstrap_sortable_helper')
  end

  def load_bs_module_tables
    bs_include_css('bootstrap_tables')
  end

  def load_bs_module_tooltip
    bs_include_js('bootstrap_tooltip') +
      bs_include_js('bootstrap_tooltip_helper') +
      bs_include_css('bootstrap_tooltip')
  end
end
