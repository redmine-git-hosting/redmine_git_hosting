class DownloadGitRevision
  unloadable

  attr_reader :repository
  attr_reader :revision
  attr_reader :format
  attr_reader :gitolite_repository_path

  attr_reader :commit_valid
  attr_reader :commit_id
  attr_reader :content_type
  attr_reader :filename


  def initialize(repository, revision, format)
    @repository = repository
    @revision   = revision
    @format     = format
    @gitolite_repository_path = repository.gitolite_repository_path

    @commit_valid  = false
    @commit_id     = nil
    @content_type  = ''
    @filename      = ''

    validate_revision
    fill_data
  end


  def content
    repository.archive(commit_id, format)
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
        repository.tags.each do |x|
          if x == revision
            commit = repository.rev_list(revision).first
            break
          end
        end
      end

      # well, let check if this is a valid commit
      commit = revision if commit.nil?

      valid_commit = repository.rev_parse(commit)

      if valid_commit == ''
        @commit_valid = false
      else
        @commit_valid = true
        @commit_id = valid_commit
      end
    end


    def fill_data
      case format
      when 'tar' then
        extension     = 'tar'
        @content_type = 'application/x-tar'
      when 'tar.gz' then
        extension     = 'tar.gz'
        @content_type = 'application/x-gzip'
      when 'zip' then
        extension     = 'zip'
        @content_type = 'application/x-zip'
      end
      @filename = "#{repository.redmine_name}-#{revision}.#{extension}"
    end

end
