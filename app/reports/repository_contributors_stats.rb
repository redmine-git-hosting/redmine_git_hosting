class RepositoryContributorsStats < ReportBase

  def initialize(repository)
    super
    @changes_for_committer = {}
  end


  def commits_per_author
    data = []

    sorted_commits_per_author_with_aliases.each do |committer_hash|
      commits = {}

      committer_hash[:committers].each do |committer|
        commits = commits.merge(count_changes_for_committer(committer)) { |key, oldval, newval| newval + oldval }
      end

      commits = Hash[commits.sort]
      commits_data = {}
      commits_data[:author_name]   = committer_hash[:name]
      commits_data[:author_mail]   = committer_hash[:mail]
      commits_data[:total_commits] = committer_hash[:commits]
      commits_data[:categories]    = commits.keys
      commits_data[:series]        = []
      commits_data[:series] << { name: l(:label_commit_plural), data: commits.values }
      data.push(commits_data)
    end

    data
  end


  def commits_per_author_global
    merged = commits_per_author_with_aliases
    data = {}
    data[:categories] = merged.map { |x| x[:name] }
    data[:series] = []
    data[:series] << { name: l(:label_commit_plural), data: merged.map { |x| x[:commits] } }
    data[:series] << { name: l(:label_change_plural), data: merged.map { |x| x[:changes] } }
    data
  end


  private


    # Generate mappings from the registered users to the comitters
    # user_committer_mapping = { name => [comitter, ...] }
    # registered_committers = [ committer,... ]
    #
    def commits_per_author_with_aliases
      return @commits_per_author_with_aliases if !@commits_per_author_with_aliases.nil?
      @commits_per_author_with_aliases = nil

      registered_committers = []
      user_committer_mapping = {}
      Changeset.select('changesets.committer, changesets.user_id')
               .where('repository_id = ? and user_id IS NOT NULL', repository.id)
               .group(:committer, :user_id)
               .includes(:user).each do |x|
        name = "#{x.user.firstname} #{x.user.lastname}"
        registered_committers << x.committer
        user_committer_mapping[[name, x.user.mail]] ||= []
        user_committer_mapping[[name, x.user.mail]] << x.committer
      end

      merged = []
      commits_by_author.each do |committer, count|
        # skip all registered users
        next if registered_committers.include?(committer)

        name = committer.gsub(%r{<.+@.+>}, '').strip
        mail = committer[/<(.+@.+)>/, 1]
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
      merged.sort! { |x, y| x[:name] <=> y[:name] }

      # merged = merged + [{name:"",commits:0,changes:0}]*(10 - merged.length) if merged.length < 10
      @commits_per_author_with_aliases = merged
      @commits_per_author_with_aliases
    end


    def sorted_commits_per_author_with_aliases
      @committers ||= commits_per_author_with_aliases.sort! { |x, y| y[:commits] <=> x[:commits] }
    end


    def count_changes_for_committer(committer)
      return @changes_for_committer[committer] if !@changes_for_committer[committer].nil?
      @changes_for_committer[committer] ||= Changeset.where('repository_id = ? AND committer = ?', repository.id, committer).group(:commit_date).order(:commit_date).count
      @changes_for_committer[committer]
    end

end
