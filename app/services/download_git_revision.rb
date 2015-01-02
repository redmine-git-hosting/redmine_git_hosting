class DownloadGitRevision
  unloadable

  attr_reader :commit_valid
  attr_reader :content_type
  attr_reader :filename


  def initialize(repository, revision, format)
    @repository = repository
    @revision   = revision
    @format     = format
    @project    = repository.project

    @commit_valid  = false
    @commit_id     = ''
    @content_type  = ''
    @filename      = ''
    @cmd_args      = []

    validate_revision
    fill_data
  end


  def content
    RedmineGitHosting::Commands.sudo_git_archive(@repository.gitolite_repository_path, @commit_id, @cmd_args)
  end


  private


    def validate_revision
      commit_id = nil

      # is the revision a branch?
      @repository.branches.each do |x|
        if x.to_s == @revision
          commit_id = x.revision
          break
        end
      end

      # is the revision a tag?
      if commit_id.nil?
        tags = RedmineGitHosting::Commands.sudo_git_tag(@repository.gitolite_repository_path)
        tags.each do |x|
          if x == @revision
            commit_id = RedmineGitHosting::Commands.sudo_git_rev_list(@repository.gitolite_repository_path, @revision).split[0]
            break
          end
        end
      end

      # well, let check if this is a valid commit_id
      if commit_id.nil?
        commit_id = @revision
      end

      valid_commit = RedmineGitHosting::Commands.sudo_git_rev_parse(@repository.gitolite_repository_path, commit_id, ['--quiet', '--verify'])

      if valid_commit == ''
        @commit_valid = false
      else
        @commit_valid = true
        @commit_id = valid_commit
      end
    end


    def fill_data
      project_name = @project.to_s.parameterize.to_s

      if project_name.length == 0
        project_name = "tarball"
      end

      case @format
        when 'tar' then
          extension     = 'tar'
          @content_type = 'application/x-tar'
          @cmd_args << "--format=tar"

        when 'tar.gz' then
          extension     = 'tar.gz'
          @content_type = 'application/x-gzip'
          @cmd_args << "--format=tar.gz"
          @cmd_args << "-7"

        when 'zip' then
          extension     = 'zip'
          @content_type = 'application/x-zip'
          @cmd_args << "--format=zip"
          @cmd_args << "-7"
      end

      @filename = "#{project_name}-#{@revision}.#{extension}"
    end

end
