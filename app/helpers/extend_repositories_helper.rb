module ExtendRepositoriesHelper

  def encoding_field(form, repository)
    content_tag(:p) do
      form.select(
        :path_encoding, [nil] + Setting::ENCODINGS,
        :label => l(:field_scm_path_encoding)
      ) + '<br />'.html_safe + l(:text_scm_path_encoding_note)
    end
  end


  def report_last_commit_field(form, repository)
    content_tag(:p) do
      form.check_box(:extra_report_last_commit, :label => l(:label_git_report_last_commit))
    end
  end


  def create_readme_field(form, repository)
    content_tag(:p) do
      hidden_field_tag("repository[create_readme]", "false") +
      content_tag(:label, l(:label_init_repo_with_readme)) +
      check_box_tag("repository[create_readme]", "true", RedmineGitHosting::Config.init_repositories_on_create?)
    end if repository.new_record?
  end


  def enable_git_annex_field(form, repository)
    content_tag(:p) do
      hidden_field_tag("repository[enable_git_annex]", "false") +
      content_tag(:label, l(:label_init_repo_with_git_annex)) +
      check_box_tag("repository[enable_git_annex]", "true")
    end if repository.new_record?
  end

end
