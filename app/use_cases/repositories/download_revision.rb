module Repositories
  class DownloadRevision

    attr_reader :repository
    attr_reader :revision
    attr_reader :format
    attr_reader :gitolite_repository_path

    attr_reader :commit_id
    attr_reader :content_type
    attr_reader :filename


    def initialize(repository, revision, format)
      @repository = repository
      @revision   = revision
      @format     = format
      @gitolite_repository_path = repository.gitolite_repository_path

      @valid_commit  = false
      @commit_id     = nil
      @content_type  = ''
      @filename      = ''

      validate_revision
      fill_data
    end


    def content
      repository.archive(commit_id, format)
    end


    def valid_commit?
      @valid_commit
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
        commit = repository.rev_parse(commit)

        if commit == ''
          @valid_commit = false
        else
          @valid_commit = true
          @commit_id = commit
        end
      end


      def fill_data
        case format
        when 'tar.gz' then
          extension     = 'tar.gz'
          @content_type = 'application/x-gzip'
        when 'zip' then
          extension     = 'zip'
          @content_type = 'application/x-zip'
        else
          extension     = 'tar'
          @content_type = 'application/x-tar'
        end
        @filename = "#{repository.redmine_name}-#{revision}.#{extension}"
      end

  end
end
