require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'sshkey'

describe RepositoryDeploymentCredentialsController do
  def self.skip_actions
    ['show']
  end

  include CrudControllerSpec::Base

  def permissions
    %i[manage_repository create_repository_deployment_credentials view_repository_deployment_credentials
       edit_repository_deployment_credentials]
  end

  def create_object
    FactoryBot.create(:repository_deployment_credential,
                      repository_id: @repository.id,
                      user_id: @member_user.id,
                      gitolite_public_key_id: FactoryBot.create(:gitolite_public_key,
                                                                user_id: @member_user.id,
                                                                key_type: 1,
                                                                key: SSHKey.generate.ssh_public_key).id)
  end

  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_deployment_credentials"
  end

  def variable_for_index
    :repository_deployment_credentials
  end

  def main_variable
    :credential
  end

  def tested_klass
    RepositoryDeploymentCredential
  end

  def valid_params_for_create
    public_key = FactoryBot.create(:gitolite_public_key,
                                   user_id: @member_user.id,
                                   key_type: 1,
                                   key: SSHKey.generate.ssh_public_key)
    { repository_deployment_credential: { gitolite_public_key_id: public_key.id, perm: 'RW+' } }
  end

  def invalid_params_for_create
    { repository_deployment_credential: { url: 'git@example.com:john_doe3/john_doe3/john_doe3.git', push_mode: 0 } }
  end

  def valid_params_for_update
    { id: @object.id, repository_deployment_credential: { perm: 'R' } }
  end

  def updated_attribute
    :perm
  end

  def updated_attribute_value
    'R'
  end

  def invalid_params_for_update
    { id: @object.id, repository_deployment_credential: { perm: '' } }
  end
end
