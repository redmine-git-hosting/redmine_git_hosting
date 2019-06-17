module ExtendRepositoriesHelper
  def encoding_field(form, repository)
    content_tag(:p) do
      form.select(
        :path_encoding, [nil] + Setting::ENCODINGS,
        label: l(:field_scm_path_encoding)
      ) + '<br />'.html_safe + l(:text_scm_path_encoding_note)
    end
  end

  def available_download_format(repository, rev = nil)
    %w[zip tar tar.gz].map { |f| [f, download_git_revision_repository_path(repository, rev: rev, download_format: f)] }
  end

  def create_readme_field(form, repository)
    return unless repository.new_record?

    content_tag(:p) do
      hidden_field_tag('repository[create_readme]', 'false', id: '') +
        content_tag(:label, l(:label_init_repo_with_readme), for: 'repository_create_readme') +
        check_box_tag('repository[create_readme]', 'true', RedmineGitHosting::Config.init_repositories_on_create?)
    end
  end

  def enable_git_annex_field(form, repository)
    return unless repository.new_record?

    content_tag(:p) do
      hidden_field_tag('repository[enable_git_annex]', 'false', id: '') +
        content_tag(:label, l(:label_init_repo_with_git_annex), for: 'repository_enable_git_annex') +
        check_box_tag('repository[enable_git_annex]', 'true')
    end
  end

  def repository_branches_list(branches)
    options_for_select branches.collect { |b| [b.to_s, b.to_s] }, selected: branches.find(&:is_default).to_s
  end

  def render_repository_quick_jump(repository)
    options = repository.project.repositories.map { |r| [r.redmine_name, edit_repository_path(r)] }
    select_tag('repository_quick_jump_box',
               options_for_select(options, selected: edit_repository_path(repository)),
               onchange: 'if (this.value != \'\') { window.location = this.value; }')
  end

  def link_to_repository(repo, current_repo)
    css_class = ['repository', (repo == current_repo ? 'selected' : ''), current_repo.type.split('::')[1].downcase].join(' ')
    link_to h(repo.name),
            { controller: 'repositories', action: 'show', id: @project, repository_id: repo.identifier_param, rev: nil, path: nil },
            class: css_class
  end

  def icon_for_url_type(url_type)
    font_awesome_icon(RepositoryGitExtra::URLS_ICONS[url_type][:icon])
  end

  def label_for_url_type(url_type)
    RepositoryGitExtra::URLS_ICONS[url_type][:label]
  end

  def render_options_for_move_repo_select_box(project)
    projects = Project.active
                      .where(Project.allowed_to_condition(User.current, :manage_repository))
                      .where.not(id: project.id)
    project_tree_options_for_select(projects, selected: project) if projects.any?
  end
end
