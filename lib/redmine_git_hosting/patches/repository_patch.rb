module RedmineGitHosting
  module Patches
    module RepositoryPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          class << self
            alias_method_chain :factory, :git_hosting
          end
        end
      end


      module ClassMethods

        def factory_with_git_hosting(klass_name, *args)
          new_repo = factory_without_git_hosting(klass_name, *args)
          if new_repo.is_a?(Repository::Git)
            if new_repo.extra.nil?
              # Note that this autoinitializes default values and hook key
              RedmineGitolite::GitHosting.logger.error { "Automatic initialization of RepositoryGitExtra failed for #{self.project.to_s}" }
            end
          end
          return new_repo
        end

      end


      module InstanceMethods

        def commits_per_month
          @date_to = Date.today
          @date_from = @date_to << 11
          @date_from = Date.civil(@date_from.year, @date_from.month, 1)
          commits_by_day = Changeset.
            where("repository_id = ? AND commit_date BETWEEN ? AND ?", self.id, @date_from, @date_to).
            group(:commit_date).
            count
          commits_by_month = [0] * 12
          commits_by_day.each {|c| commits_by_month[(@date_to.month - c.first.to_date.month) % 12] += c.last }

          changes_by_day = Change.
            joins(:changeset).
            where("#{Changeset.table_name}.repository_id = ? AND #{Changeset.table_name}.commit_date BETWEEN ? AND ?", self.id, @date_from, @date_to).
            group(:commit_date).
            count
          changes_by_month = [0] * 12
          changes_by_day.each {|c| changes_by_month[(@date_to.month - c.first.to_date.month) % 12] += c.last }

          fields = []
          12.times {|m| fields << month_name(((Date.today.month - 1 - m) % 12) + 1)}

          data = {}
          data[:categories] = fields
          data[:series] = []
          data[:series].push({:name => l(:label_revision_plural), :data => commits_by_month})
          data[:series].push({:name => l(:label_change_plural), :data => changes_by_month})

          return data
        end


        def commits_per_author
          commits_by_author = Changeset.where("repository_id = ?", self.id).group(:committer).count
          commits_by_author.to_a.sort! {|x, y| x.last <=> y.last}

          changes_by_author = Change.joins(:changeset).where("#{Changeset.table_name}.repository_id = ?", self.id).group(:committer).count
          h = changes_by_author.inject({}) {|o, i| o[i.first] = i.last; o}

          fields = commits_by_author.collect {|r| r.first}
          commits_data = commits_by_author.collect {|r| r.last}
          changes_data = commits_by_author.collect {|r| h[r.first] || 0}

          fields = fields + [""]*(10 - fields.length) if fields.length<10
          commits_data = commits_data + [0]*(10 - commits_data.length) if commits_data.length<10
          changes_data = changes_data + [0]*(10 - changes_data.length) if changes_data.length<10

          # Remove email adress in usernames
          fields = fields.collect {|c| c.gsub(%r{<.+@.+>}, '') }

          data = {}
          data[:categories] = fields
          data[:series] = []
          data[:series].push({:name => l(:label_revision_plural), :data => commits_data})
          data[:series].push({:name => l(:label_change_plural), :data => changes_data})

          return data
        end

      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitHosting::Patches::RepositoryPatch)
end
