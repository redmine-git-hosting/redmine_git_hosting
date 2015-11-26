module Repositories
  class BuildPayload < Base

    def initialize(*args)
      super
      @payloads = []
    end


    def call
      build_payloads
    end


    def refs
      options
    end


    private


      # Returns an array of GitHub post-receive hook style hashes
      # http://help.github.com/post-receive-hooks/
      #
      def build_payloads
        refs.each do |ref|
          # Get revisions range
          range = get_revisions_from_ref(ref)
          next if range.nil?
          @payloads << build_payload(ref, range)
        end
        @payloads
      end


      def get_revisions_from_ref(ref)
        oldhead, newhead, refname = ref.split(',')

        # Only pay attention to branch updates
        return nil if !refname.match(/refs\/heads\//)

        # Get branch name
        branch_name = refname.gsub('refs/heads/', '')

        if newhead.match(/\A0{40}\z/)
          # Deleting a branch
          logger.info("Deleting branch '#{branch_name}'")
          range = nil
        elsif oldhead.match(/\A0{40}\z/)
          # Creating a branch
          logger.info("Creating branch '#{branch_name}'")
          range = newhead
        else
          range = "#{oldhead}..#{newhead}"
        end

        range
      end


      def build_payload(ref, range)
        revisions_in_range = get_revisions_in_range(range)
        logger.debug("Revisions in range : #{revisions_in_range.join(' ')}")

        # Get refs
        oldhead, newhead, refname = ref.split(',')

        # Build payload hash
        repository.github_payload
                  .merge({ before: oldhead, after: newhead, ref: refname, commits: build_commits_list(revisions_in_range) })
      end


      def build_commits_list(revisions_in_range)
        commits_list = []
        revisions_in_range.each do |rev|
          changeset = repository.find_changeset_by_name(rev)
          next if changeset.nil?
          commits_list << changeset.github_payload
        end
        commits_list
      end


      def get_revisions_in_range(range)
        repository.rev_list(range, ['--reverse'])
      end

  end
end
