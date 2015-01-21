class DownloadGitRevisionController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_repository
  before_filter :can_download_git_revision
  before_filter :set_download
  before_filter :validate_download

  helper :git_hosting


  def index
    begin
      send_data(@download.content, filename: @download.filename, type: @download.content_type)
    rescue => e
      flash.now[:error] = l(:git_archive_timeout, timeout: e.output)
      render_404
    end
  end


  private


    def set_repository
      begin
        @repository = Repository::Xitolite.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        render_404
      else
        @project = @repository.project
        render_404 if @project.nil?
      end
    end


    def can_download_git_revision
      render_403 unless view_context.user_allowed_to(:download_git_revision, @project)
    end


    def set_download
      @download = DownloadGitRevision.new(@repository, download_revision, download_format)
    end


    def download_revision
      @download_revision ||= (params[:rev] || 'master')
    end


    def download_format
      @download_format ||= (params[:download_format] || 'tar')
    end


    def validate_download
      if !@download.commit_valid
        flash.now[:error] = l(:error_download_revision_no_such_commit, commit: download_revision)
        render_404
      end
    end

end
