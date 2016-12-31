require_dependency 'changeset'

module RedmineGitHosting
  module Patches
    module ChangesetPatch

      def github_payload
        data = {}
        data[:id]        = revision
        data[:message]   = comments
        data[:timestamp] = committed_on
        data[:author]    = author_data
        data[:added]     = added_files
        data[:modified]  = modified_files
        data[:removed]   = removed_files
        data[:url]       = url_for_revision(revision)
        data
      end


      def author_data
        { name: author_name, email: author_email }
      end


      def author_name
        RedmineGitHosting::Utils::Git.author_name(committer)
      end


      def author_email
        RedmineGitHosting::Utils::Git.author_email(committer)
      end


      def added_files
        filechanges_by_action('A')
      end


      def modified_files
        filechanges_by_action('M')
      end


      def removed_files
        filechanges_by_action('D')
      end


      def filechanges_by_action(action)
        filechanges.select { |c| c.action == action }.map(&:path)
      end


      def url_for_revision(revision)
        Rails.application.routes.url_helpers.url_for(
          controller: 'repositories', action: 'revision',
          id: project, repository_id: repository.identifier_param, rev: revision,
          only_path: false, host: Setting['host_name'], protocol: Setting['protocol']
        )
      end

    end
  end
end

unless Changeset.included_modules.include?(RedmineGitHosting::Patches::ChangesetPatch)
  Changeset.send(:prepend, RedmineGitHosting::Patches::ChangesetPatch)
end
