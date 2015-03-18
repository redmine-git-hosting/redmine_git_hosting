module GitolitePluginSettingsHelper

  def render_gitolite_params_status(params)
    content_tag(:ul, class: 'list-unstyled') do
      content = ''
      params.each do |param, installed|
        content << content_tag(:li, style: 'padding: 2px;') do
          image_tag(image_for_param(installed), style: 'vertical-align: bottom;') +
          content_tag(:em, param)
        end
      end
      content.html_safe
    end
  end


  def image_for_param(bool)
    bool ? 'true.png' : 'exclamation.png'
  end


  def render_gitolite_version(version)
    if version.nil?
      css_class = 'label label-important'
      label = l(:label_unknown_gitolite_version)
    else
      css_class = 'label label-success'
      label = version
    end
    content_tag(:span, label, class: css_class)
  end


  def render_temp_dir_writeable(state, label)
    css_class = state ? 'label label-success' : 'label label-important'
    content_tag(:span, label, class: css_class)
  end


  def gitolite_plugin_settings_tabs
    [
      { name: 'gitolite_config_ssh',        partial: 'settings/redmine_git_hosting/gitolite_config_ssh',     label: :label_tab_ssh },
      { name: 'gitolite_config_storage',    partial: 'settings/redmine_git_hosting/gitolite_config_storage', label: :label_tab_storage },
      { name: 'gitolite_config_file',       partial: 'settings/redmine_git_hosting/gitolite_config_file',    label: :label_tab_config_file },
      { name: 'gitolite_config_global',     partial: 'settings/redmine_git_hosting/gitolite_config_global',  label: :label_tab_global },
      { name: 'gitolite_config_access',     partial: 'settings/redmine_git_hosting/gitolite_config_access',  label: :label_tab_access },
      { name: 'gitolite_config_hooks',      partial: 'settings/redmine_git_hosting/gitolite_config_hooks',   label: :label_tab_hooks },
      { name: 'gitolite_config_cache',      partial: 'settings/redmine_git_hosting/gitolite_config_cache',   label: :label_tab_cache },
      { name: 'gitolite_config_notify',     partial: 'settings/redmine_git_hosting/gitolite_config_notify',  label: :label_tab_notify },
      { name: 'gitolite_redmine_config',    partial: 'settings/redmine_git_hosting/redmine_config',          label: :label_tab_redmine },
      { name: 'gitolite_sidekiq_interface', partial: 'settings/redmine_git_hosting/sidekiq_interface',       label: :label_tab_sidekiq_interface },
      { name: 'gitolite_config_test',       partial: 'settings/redmine_git_hosting/gitolite_config_test',    label: :label_tab_config_test },
      { name: 'gitolite_recycle_bin',       partial: 'settings/redmine_git_hosting/gitolite_recycle_bin',    label: :label_tab_gitolite_recycle_bin },
      { name: 'gitolite_rescue',            partial: 'settings/redmine_git_hosting/gitolite_rescue',         label: :label_tab_gitolite_rescue }
    ]
  end


  def git_cache_options
    [
      ['Cache Disabled', '0'],
      ['Until next commit', '-1'],
      ['1 Minute or until next commit', '60'],
      ['15 Minutes or until next commit', '900'],
      ['1 Hour or until next commit', '3600'],
      ['1 Day or until next commit', '86400']
    ]
  end


  def git_cache_adapters
    [
      ['Database', 'database'],
      ['Memcached', 'memcached'],
      ['Redis', 'redis']
    ]
  end


  def log_level_options
    [
      [l(:label_debug), 'debug'],
      [l(:label_info), 'info'],
      [l(:label_warn), 'warn'],
      [l(:label_error), 'error']
    ]
  end

end
