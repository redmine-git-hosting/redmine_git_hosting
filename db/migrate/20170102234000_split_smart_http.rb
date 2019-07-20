class SplitSmartHttp < ActiveRecord::Migration[4.2]
  def up
    add_column :repository_git_extras, :git_https, :boolean, default: false, after: :git_http
    add_column :repository_git_extras, :git_ssh,   :boolean, default: true,  after: :git_https
    add_column :repository_git_extras, :git_go,    :boolean, default: false, after: :git_https

    add_column :repository_git_extras, :git_http_temp, :boolean, default: false, after: :git_http

    RepositoryGitExtra.reset_column_information

    RepositoryGitExtra.all.each do |git_extra|
      case git_extra[:git_http]
      when 1 # HTTPS only
        git_extra.update_column(:git_https, true)
      when 2 # HTTPS and HTTP
        git_extra.update_column(:git_https, true)
        git_extra.update_column(:git_http_temp, true)
      else # HTTP only
        git_extra.update_column(:git_http_temp, true)
      end
    end

    remove_column :repository_git_extras, :git_http
    rename_column :repository_git_extras, :git_http_temp, :git_http
  end

  def down
    add_column :repository_git_extras, :git_http_temp, :integer, after: :git_http

    RepositoryGitExtra.reset_column_information

    RepositoryGitExtra.all.each do |git_extra|
      if git_extra[:git_https] && git_extra[:git_http]
        git_extra.update_column(:git_http_temp, 2)
      elsif git_extra[:git_https]
        git_extra.update_column(:git_http_temp, 1)
      elsif git_extra[:git_http]
        git_extra.update_column(:git_http_temp, 3)
      end
    end

    remove_column :repository_git_extras, :git_https
    remove_column :repository_git_extras, :git_ssh
    remove_column :repository_git_extras, :git_go

    remove_column :repository_git_extras, :git_http
    rename_column :repository_git_extras, :git_http_temp, :git_http
  end
end
