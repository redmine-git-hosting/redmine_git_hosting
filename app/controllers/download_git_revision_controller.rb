class DownloadGitRevisionController < ApplicationController

  include XitoliteRepositoryFinder

  before_filter :find_xitolite_repository
  before_filter :can_download_git_revision
  before_filter :set_download
  before_filter :validate_download

  helper :redmine_bootstrap_kit


  def index
    begin
      send_data(@download.content, filename: @download.filename, type: @download.content_type)
    rescue => e
      flash.now[:error] = l(:git_archive_timeout, timeout: e.output)
      render_404
    end
  end


  private


    def find_repository_param
      params[:id]
    end


    def can_download_git_revision
      render_403 unless User.current.allowed_to_download?(@repository)
    end


    def set_download
      @download = Repositories::DownloadRevision.new(@repository, download_revision, download_format)
    end


    def download_revision
      @download_revision ||= (params[:rev] || 'master')
    end


    def download_format
      @download_format ||= (params[:download_format] || 'tar')
    end


    def validate_download
      if !@download.valid_commit?
        flash.now[:error] = l(:error_download_revision_no_such_commit, commit: download_revision)
        render_404
      end
    end

end
