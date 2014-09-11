require_dependency 'repository'

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

        def global_statistics
          total_commits = Changeset.where("repository_id = ?", self.id).count
          first_commit  = Changeset.where("repository_id = ?", self.id).order('commit_date ASC').first
          last_commit   = Changeset.where("repository_id = ?", self.id).order('commit_date ASC').last
          active_for    = (last_commit.commit_date - first_commit.commit_date).to_i
          committers    = Changeset.where("repository_id = ?", self.id).where("user_id IS NOT NULL").select(:user_id).uniq.count
          committers   += Changeset.where("repository_id = ?", self.id).where(user_id: nil).select(:committer).uniq.count

          data = {}
          data[l(:label_total_commits)]               = total_commits
          data[l(:label_total_contributors)]          = committers
          data[l(:label_first_commit_date)]           = first_commit.commit_date
          data[l(:label_latest_commit_date)]          = last_commit.commit_date
          data[l(:label_active_for)]                  = "#{active_for} #{l(:label_active_days)}"
          data[l(:label_average_commit_per_day)]      = total_commits.fdiv(active_for).round(2)
          data[l(:label_average_contributor_commits)] = total_commits.fdiv(committers).round(2)

          return data
        end


        def commits_per_hours
          total_commits_by_hour = Changeset.where("repository_id = ?", self.id).map(&:committed_on)

          commits_by_hour = [0] * 24
          total_commits_by_hour.each {|c| commits_by_hour[get_hour_from_date(c)] += 1 }

          hours = (0..23).step(1).to_a
          new_hours = []
          hours.each { |h| new_hours.push("#{h}h") }

          data = {}
          data[:categories]    = new_hours
          data[:series]        = []
          data[:series].push({:name => l(:label_commit_plural), :data => commits_by_hour})

          return data
        end


        def commits_per_day
          total_commits_by_day = Changeset.where("repository_id = ?", self.id).group(:commit_date).order(:commit_date).count
          total_changes_by_day = Change.joins(:changeset).where("#{Changeset.table_name}.repository_id = ?", self.id).group(:commit_date).order(:commit_date).count

          data = {}
          data[:categories]    = total_commits_by_day.keys
          data[:series]        = []
          data[:series].push({:name => l(:label_commit_plural), :data => total_commits_by_day.values})
          data[:series].push({:name => l(:label_change_plural), :data => total_changes_by_day.values})

          return data
        end


        def commits_per_weekday
          week_day = {}
          week_day[l(:label_monday)]    = 0
          week_day[l(:label_tuesday)]   = 0
          week_day[l(:label_wednesday)] = 0
          week_day[l(:label_thursday)]  = 0
          week_day[l(:label_friday)]    = 0
          week_day[l(:label_saturday)]  = 0
          week_day[l(:label_sunday)]    = 0

          total_commits = Changeset.where("repository_id = ?", self.id).group(:commit_date).count
          total_commits.each do |commit_date, commit_count|
            case commit_date.to_date.wday
              when 0
                week_day[l(:label_sunday)] += commit_count
              when 1
                week_day[l(:label_monday)] += commit_count
              when 2
                week_day[l(:label_tuesday)] += commit_count
              when 3
                week_day[l(:label_wednesday)] += commit_count
              when 4
                week_day[l(:label_thursday)] += commit_count
              when 5
                week_day[l(:label_friday)] += commit_count
              when 6
                week_day[l(:label_saturday)] += commit_count
            end
          end

          data = {}
          data[:name] = l(:label_commit_plural)
          data[:data] = []

          week_day.each do |key, value|
            data[:data].push([key, value])
          end

          return [data]
        end


        def commits_per_month
          date_to = Date.today
          commits_by_day = Changeset.
            where("repository_id = ?", self.id).
            group(:commit_date).
            count
          commits_by_month = [0] * 12
          commits_by_day.each {|c| commits_by_month[(date_to.month - c.first.to_date.month) % 12] += c.last }

          changes_by_day = Change.
            joins(:changeset).
            where("#{Changeset.table_name}.repository_id = ?", self.id).
            group(:commit_date).
            count
          changes_by_month = [0] * 12
          changes_by_day.each {|c| changes_by_month[(date_to.month - c.first.to_date.month) % 12] += c.last }

          fields = []
          12.times {|m| fields << month_name(((Date.today.month - 1 - m) % 12) + 1)}

          data = {}
          data[:categories] = fields.reverse
          data[:series] = []
          data[:series].push({:name => l(:label_commit_plural), :data => commits_by_month[0..11].reverse})
          data[:series].push({:name => l(:label_change_plural), :data => changes_by_month[0..11].reverse})

          return data
        end

        def commits_per_author_with_aliases
          commits_by_author = Changeset.where("repository_id = ?", self.id).group(:committer).count
          changes_by_author = Change.joins(:changeset).where("#{Changeset.table_name}.repository_id = ?", self.id).group(:committer).count

          # generate mappings from the registered users to the comitters
          # user_committer_mapping = { name => [comitter, ...] }
          # registered_committers = [ committer,... ]
          registered_committers = []
          user_committer_mapping = {}
          Changeset.where(repository_id: self.id).where("user_id IS NOT NULL").group(:committer).includes(:user).each do |x|
            name = "#{x.user.firstname} #{x.user.lastname}"
            registered_committers << x.committer
            user_committer_mapping[[name,x.user.mail]] ||= []
            user_committer_mapping[[name,x.user.mail]] << x.committer
          end

          merged = []
          commits_by_author.each do |committer, count|
            # skip all registered users
            next if registered_committers.include?(committer)

            name = committer.gsub(%r{<.+@.+>}, '').strip
            mail = committer[/<(.+@.+)>/,1]
            merged << { name: name, mail: mail, commits: count, changes: changes_by_author[committer] || 0, committers: [committer] }
          end
          user_committer_mapping.each do |identity, committers|
            count = 0
            changes = 0
            committers.each do |c|
              count += commits_by_author[c] || 0
              changes += changes_by_author[c] || 0
            end
            merged << { name: identity[0], mail: identity[1], commits: count, changes: changes, committers: committers }
          end

          # sort by name
          merged.sort! {|x, y| x[:name] <=> y[:name]}

          # merged = merged + [{name:"",commits:0,changes:0}]*(10 - merged.length) if merged.length < 10
          return merged
        end

        def commits_per_author_global
          merged = commits_per_author_with_aliases

          data = {}
          data[:categories] = merged.map { |x| x[:name] }
          data[:series] = []
          data[:series].push({:name => l(:label_commit_plural), :data => merged.map { |x| x[:commits] }})
          data[:series].push({:name => l(:label_change_plural), :data => merged.map { |x| x[:changes] }})

          return data
        end


        def commits_per_author
          data = []
          committers = commits_per_author_with_aliases

          # sort by commits (descending)
          committers.sort! {|x, y| y[:commits] <=> x[:commits]}

          committers.each do |committer_hash|
            commits = {}

            committer_hash[:committers].each do |committer|
              c = Changeset.where("repository_id = ? AND committer = ?", self.id, committer).group(:commit_date).order(:commit_date).count
              commits = commits.merge(c){|key, oldval, newval| newval + oldval}
            end

            commits = Hash[commits.sort]
            commits_data = {}
            commits_data[:author_name]   = committer_hash[:name]
            commits_data[:author_mail]   = committer_hash[:mail]
            commits_data[:total_commits] = committer_hash[:commits]
            commits_data[:categories]    = commits.keys
            commits_data[:series]        = []
            commits_data[:series].push({:name => l(:label_commit_plural), :data => commits.values})
            data.push(commits_data)
          end

          return data
        end


        private


        def get_hour_from_date(date)
          return nil unless date
          time = date.to_time
          zone = User.current.time_zone
          local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
          local.hour
        end

      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitHosting::Patches::RepositoryPatch)
end
