class GitNotifier
  unloadable


  attr_reader :email_prefix
  attr_reader :sender_address
  attr_reader :default_list
  attr_reader :mail_mapping


  def initialize(repository)
    @repository     = repository
    @project        = repository.project

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
    if !@repository.git_notification.nil? && !@repository.git_notification.prefix.empty?
      @email_prefix = @repository.git_notification.prefix
    else
      @email_prefix = RedmineGitolite::Config.get_setting(:gitolite_notify_global_prefix)
    end
  end


  def set_sender_address
    if !@repository.git_notification.nil? && !@repository.git_notification.sender_address.empty?
      @sender_address = @repository.git_notification.sender_address
    else
      @sender_address = RedmineGitolite::Config.get_setting(:gitolite_notify_global_sender_address)
    end
  end


  def set_default_list
    @default_list = @project.member_principals.map(&:user).compact.uniq
                                                          .select{|user| user.allowed_to?(:receive_git_notifications, @project)}
                                                          .map(&:mail).uniq.sort
  end


  def set_mail_mapping
    mail_mapping = {}

    # First collect all project users
    default_users = @default_list.map{ |mail| mail_mapping[mail] = :project }

    # Then add global include list
    RedmineGitolite::Config.get_setting(:gitolite_notify_global_include).sort.map{ |mail| mail_mapping[mail] = :global }

    # Then filter
    mail_mapping = filter_list(mail_mapping)

    # Then add local include list
    if !@repository.git_notification.nil? && !@repository.git_notification.include_list.empty?
      @repository.git_notification.include_list.sort.map{ |mail| mail_mapping[mail] = :local }
    end

    @mail_mapping = mail_mapping
  end


  def filter_list(merged_map)
    mail_mapping = {}
    exclude_list = []

    # Build exclusion list
    if !RedmineGitolite::Config.get_setting(:gitolite_notify_global_exclude).empty?
      exclude_list = RedmineGitolite::Config.get_setting(:gitolite_notify_global_exclude)
    end

    if !@repository.git_notification.nil? && !@repository.git_notification.exclude_list.empty?
      exclude_list = exclude_list + @repository.git_notification.exclude_list
    end

    exclude_list = exclude_list.uniq.sort

    merged_map.each do |mail, from|
      mail_mapping[mail] = from unless exclude_list.include?(mail)
    end

    return mail_mapping
  end

end
