class DownloadGitRevision
  unloadable

  attr_reader :repository
  attr_reader :revision
  attr_reader :format
  attr_reader :project
  attr_reader :gitolite_repository_path

  attr_reader :commit_valid
  attr_reader :commit_id
  attr_reader :content_type
  attr_reader :filename
  attr_reader :cmd_args


  def initialize(repository, revision, format)
    @repository = repository
    @revision   = revision
    @format     = format
    @project    = repository.project
    @gitolite_repository_path = repository.gitolite_repository_path

    @commit_valid  = false
    @commit_id     = nil
    @content_type  = ''
    @filename      = ''
    @cmd_args      = []

    validate_revision
    fill_data
  end


  def content
    RedmineGitHosting::Commands.sudo_git_archive(gitolite_repository_path, commit_id, cmd_args)
  end


  private


    def validate_revision
      commit = nil

      # is the revision a branch?
      repository.branches.each do |x|
        if x.to_s == revision
          commit = x.revision
          break
        end
      end

      # is the revision a tag?
      if commit.nil?
        tags = RedmineGitHosting::Commands.sudo_git_tag(gitolite_repository_path)
        tags.each do |x|
          if x == revision
            commit = RedmineGitHosting::Commands.sudo_git_rev_list(gitolite_repository_path, revision).split[0]
            break
          end
        end
      end

      # well, let check if this is a valid commit
      commit = revision if commit.nil?

      valid_commit = RedmineGitHosting::Commands.sudo_git_rev_parse(gitolite_repository_path, commit, ['--quiet', '--verify'])

      if valid_commit == ''
        @commit_valid = false
      else
        @commit_valid = true
        @commit_id = valid_commit
      end
    end


    def fill_data
      project_name = project.to_s.parameterize.to_s
      project_name = "tarball" if project_name.length == 0

      case format
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

      @filename = "#{project_name}-#{revision}.#{extension}"
    end

end
