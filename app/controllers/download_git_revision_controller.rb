class DownloadGitRevisionController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_repository
  before_filter :set_project
  before_filter :can_download_git_revision

  helper :git_hosting


  def index
    if !params[:rev]
      revision = "master"
    else
      revision = params[:rev]
    end

    format = params[:download_format]

    download = DownloadGitRevision.new(@repository, revision, format)

    if !download.commit_valid
      flash.now[:error] = l(:error_download_revision_no_such_commit, :commit => revision)
      render_404
      return
    end

    begin
      content = download.content
    rescue => e
      flash.now[:error] = l(:git_archive_timeout, :timeout => e.output)
      render_404
      return
    end

    send_data(content, :filename => download.filename, :type => download.content_type)
  end


  private


    def set_repository
      @repository = Repository.find_by_id(params[:id])
      if @repository.nil?
        render_404
      end
    end


    def set_project
      @project = @repository.project
      if @project.nil?
        render_404
      end
    end


    def can_download_git_revision
      render_403 unless view_context.user_allowed_to(:download_git_revision, @project)
    end

end
