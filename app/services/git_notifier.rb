class GitNotifier
  unloadable

  attr_reader :repository
  attr_reader :project
  attr_reader :git_notification

  attr_reader :email_prefix
  attr_reader :sender_address
  attr_reader :default_list
  attr_reader :mail_mapping


  def initialize(repository)
    @repository       = repository
    @project          = repository.project
    @git_notification = repository.git_notification

    @email_prefix   = ''
    @sender_address = ''
    @default_list   = []
    @mail_mapping   = {}

    build_notifier
  end


  def mailing_list
    @mail_mapping.keys
  end


  private


    def build_notifier
      set_email_prefix
      set_sender_address
      set_default_list
      set_mail_mapping
    end


    def set_email_prefix
      @email_prefix = RedmineGitHosting::Config.gitolite_notify_global_prefix
      @email_prefix = git_notification.prefix unless (git_notification.nil? || git_notification.new_record?)
    end


    def set_sender_address
      @sender_address = RedmineGitHosting::Config.gitolite_notify_global_sender_address
      @sender_address = git_notification.sender_address unless (git_notification.nil? || git_notification.new_record? || git_notification.sender_address.empty?)
    end


    def project_users
      project.member_principals.map(&:user).compact
    end


    def allowed_users
      project_users.select{ |u| u.allowed_to?(:receive_git_notifications, project) }
    end


    def set_default_list
      @default_list = allowed_users.map(&:mail).uniq.sort
    end


    def global_include_list
      RedmineGitHosting::Config.gitolite_notify_global_include
    end


    def global_exclude_list
      RedmineGitHosting::Config.gitolite_notify_global_exclude
    end


    def repository_include_list
      (git_notification.nil? || git_notification.new_record?) ? [] : git_notification.include_list
    end


    def repository_exclude_list
      (git_notification.nil? || git_notification.new_record?) ? [] : git_notification.exclude_list
    end


    def set_mail_mapping
      mail_mapping = {}

      # First collect all project users
      default_list.map{ |mail| mail_mapping[mail] = :project }

      # Then add global include list
      global_include_list.sort.map{ |mail| mail_mapping[mail] = :global }

      # Then filter
      mail_mapping = filter_list(mail_mapping)

      # Then add local include list
      repository_include_list.sort.map{ |mail| mail_mapping[mail] = :local }

      @mail_mapping = mail_mapping
    end


    def filter_list(merged_map)
      mail_mapping = {}

      # Build exclusion list
      exclude_list = []
      exclude_list = exclude_list.concat(global_exclude_list)
      exclude_list = exclude_list.concat(repository_exclude_list)
      exclude_list = exclude_list.uniq.sort

      merged_map.each do |mail, from|
        mail_mapping[mail] = from unless exclude_list.include?(mail)
      end

      mail_mapping
    end

end
