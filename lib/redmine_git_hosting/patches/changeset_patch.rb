require_dependency 'changeset'

module RedmineGitHosting
  module Patches
    module ChangesetPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end


      module InstanceMethods

        def to_hash
          {
            id:        revision,
            message:   comments,
            timestamp: committed_on,
            added:     filechanges.select { |c| c.action == 'A' }.map(&:path),
            modified:  filechanges.select { |c| c.action == 'M' }.map(&:path),
            removed:   filechanges.select { |c| c.action == 'D' }.map(&:path),
            url:       url_for_revision(revision),
            author:    { name: author_name, email: author_email }
          }
        end


        def author_name
          committer.gsub(/\A([^<]+)\s+.*\z/, '\1')
        end


        def author_email
          committer.gsub(/\A.*<([^>]+)>.*\z/, '\1')
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
end

unless Changeset.included_modules.include?(RedmineGitHosting::Patches::ChangesetPatch)
  Changeset.send(:include, RedmineGitHosting::Patches::ChangesetPatch)
end
