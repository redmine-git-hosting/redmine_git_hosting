class DownloadGitRevisionController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :can_download_git_revision
  before_filter :set_repository_variable
  before_filter :set_project_variable

  helper :git_hosting


  def index
    commit = nil
    format = params[:download_format]

    if !params[:rev]
      rev = "master"
    else
      rev = params[:rev]
    end

    # is the revision a branch?
    @repository.branches.each do |x|
      if x.to_s == rev
        commit = x.revision
        break
      end
    end

    # is the revision a tag?
    if commit.nil?
      tags = RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{@repository.gitolite_repository_path}' tag").split
      tags.each do |x|
        if x == rev
          commit = RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{@repository.gitolite_repository_path}' rev-list #{rev}").split[0]
          break
        end
      end
    end

    # well, let check if this is a commit then
    if commit.nil?
      commit = rev
    end

    valid_commit = RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{@repository.gitolite_repository_path}' rev-parse --quiet --verify #{commit}")

    if valid_commit == ''
      flash.now[:error] = l(:error_download_revision_no_such_commit, :commit => commit)
      render_404
      return
    end

    project_name = @project.to_s.parameterize.to_s

    if project_name.length == 0
      project_name = "tarball"
    end

    cmd_args = ""

    case format
      when 'tar' then
        extension = 'tar'
        content_type = 'application/x-tar'
        cmd_args << " --format=tar"
      when 'tar.gz' then
        extension = 'tar.gz'
        content_type = 'application/x-gzip'
        cmd_args << " --format=tar.gz"
        cmd_args << " -7"
      when 'zip' then
        extension = 'zip'
        content_type = 'application/x-zip'
        cmd_args << " --format=zip"
        cmd_args << " -7"
    end

    begin
      content = RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{@repository.gitolite_repository_path}' archive #{cmd_args} #{valid_commit}")
    rescue => e
      flash.now[:error] = l(:git_archive_timeout, :timeout => e.message)
      render_404
      return
    end

    send_data(content, :filename => "#{project_name}-#{rev}.#{extension}", :type => content_type)
  end


  private


  def can_download_git_revision
    render_403 unless view_context.user_allowed_to(:download_git_revision, @project)
  end


  def set_repository_variable
    @repository = Repository.find_by_id(params[:repository_id])
    if @repository.nil?
      render_404
    end
  end


  def set_project_variable
    @project = @repository.project
    if @project.nil?
      render_404
    end
  end

end
