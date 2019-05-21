require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitConfigKeysController do
  include CrudControllerSpec::Base

  def permissions
    [:manage_repository, :create_repository_git_config_keys, :view_repository_git_config_keys, :edit_repository_git_config_keys]
  end

  def create_object
    FactoryBot.create(:repository_git_config_key, repository_id: @repository.id)
  end

  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_git_config_keys"
  end

  def variable_for_index
    :repository_git_config_keys
  end

  def main_variable
    :git_config_key
  end

  def tested_klass
    RepositoryGitConfigKey
  end

  def valid_params_for_create
    { repository_git_config_key: { key: 'foo.bar1', value: 0, type: 'RepositoryGitConfigKey::GitConfig' } }
  end

  def invalid_params_for_create
    { repository_git_config_key: { key: '', value: 0 } }
  end

  def valid_params_for_update
    { id: @object.id, repository_git_config_key: { key: 'foo.bar1', value: 1 } }
  end

  def updated_attribute
    :value
  end

  def updated_attribute_value
    '1'
  end

  def invalid_params_for_update
    { id: @object.id, repository_git_config_key: { key: 'foo', value: 1 } }
  end

  private

  def base_options
    { repository_id: @repository.id, type: 'git_keys' }.clone
  end
end
