require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryMirrorsController do
  include CrudControllerSpec::Base

  def permissions
    %i[manage_repository create_repository_mirrors view_repository_mirrors edit_repository_mirrors push_repository_mirrors]
  end

  def create_object
    FactoryBot.create(:repository_mirror, repository_id: @repository.id)
  end

  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_mirrors"
  end

  def variable_for_index
    :repository_mirrors
  end

  def main_variable
    :mirror
  end

  def tested_klass
    RepositoryMirror
  end

  def valid_params_for_create
    { repository_mirror: { url: 'ssh://git@example.com:22/john_doe2/john_doe2/john_doe2.git', push_mode: 0 } }
  end

  def invalid_params_for_create
    { repository_mirror: { url: 'git@example.com:john_doe3/john_doe3/john_doe3.git', push_mode: 0 } }
  end

  def valid_params_for_update
    { id: @object.id, repository_mirror: { url: 'ssh://git@redmine.example.org/project1/project2/project3/project14.git' } }
  end

  def updated_attribute
    :url
  end

  def updated_attribute_value
    'ssh://git@redmine.example.org/project1/project2/project3/project14.git'
  end

  def invalid_params_for_update
    { id: @object.id, repository_mirror: { url: 'git@example.com:john_doe3/john_doe3/john_doe3.git' } }
  end

  describe 'GET #push' do
    context 'with sufficient permissions' do
      it 'renders the :push view' do
        set_session_user(@member_user)
        get :push,
            params: { repository_id: @repository.id, id: @object.id }
      end
    end

    context 'with unsufficient permissions' do
      it 'renders 403' do
        set_session_user(@anonymous_user)
        get :push,
            params: { repository_id: @repository.id, id: @object.id }
        check_status(403)
      end
    end
  end
end
