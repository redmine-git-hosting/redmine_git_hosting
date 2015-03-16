require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitConfigKeysController do

  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_git_config_keys"
  end

  before(:all) do
    @project        = FactoryGirl.create(:project)
    @repository     = FactoryGirl.create(:repository_gitolite, :project_id => @project.id)
    @git_config_key = FactoryGirl.create(:repository_git_config_key, :repository_id => @repository.id)
    @admin_user     = FactoryGirl.create(:user, :admin => true)
    @no_right_user  = FactoryGirl.create(:user)
    @repository2    = FactoryGirl.create(:repository_gitolite, :project_id => @project.id, :identifier => 'gck-test')
  end


  def set_admin_session
    request.session[:user_id] = @admin_user.id
  end


  def set_no_right_session
    request.session[:user_id] = @no_right_user.id
  end


  describe "GET #index" do
    context "with sufficient permissions" do
      before(:each){ set_admin_session }

      it "populates an array of repository_git_config_keys" do
        get :index, :repository_id => @repository.id
        expect(assigns(:repository_git_config_keys)).to eq [@git_config_key]
      end

      it "renders the :index view" do
        get :index, :repository_id => @repository.id
        expect(response).to render_template(:index)
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        get :index, :repository_id => @repository.id
        expect(response.status).to eq 403
      end
    end
  end


  describe "GET #show" do
    before do
      Setting.rest_api_enabled = 1
    end

    context "with sufficient permissions" do
      it "renders 200" do
        get :show, :repository_id => @repository.id, :id => @git_config_key.id, :format => 'json', :key => @admin_user.api_key
        expect(response.status).to eq 200
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        get :show, :repository_id => @repository.id, :id => @git_config_key.id, :format => 'json', :key => @no_right_user.api_key
        expect(response.status).to eq 403
      end
    end
  end


  describe "GET #new" do
    context "with sufficient permissions" do
      before(:each){ set_admin_session }

      it "assigns a new RepositoryGitConfigKey to @git_config_key" do
        get :new, :repository_id => @repository.id
        expect(assigns(:git_config_key)).to be_an_instance_of(RepositoryGitConfigKey)
      end

      it "renders the :new template" do
        get :new, :repository_id => @repository.id
        expect(response).to render_template(:new)
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        get :new, :repository_id => @repository.id
        expect(response.status).to eq 403
      end
    end
  end


  describe "POST #create" do
    context "with sufficient permissions" do
      before(:each){ set_admin_session }

      context "with valid attributes" do
        it "saves the new git_config_key in the database" do
          expect{
            xhr :post, :create, :repository_id => @repository.id,
                                :repository_git_config_key => {
                                  :key   => 'foo.bar1',
                                  :value => 0
                                }
          }.to change(RepositoryGitConfigKey, :count).by(1)
        end

        it "redirects to the repository page" do
          xhr :post, :create, :repository_id => @repository.id,
                              :repository_git_config_key => {
                                :key   => 'foo.bar2',
                                :value => 0
                              }
          expect(response.status).to eq 200
        end
      end

      context "with invalid attributes" do
        it "does not save the new post_receive_url in the database" do
          expect{
            xhr :post, :create, :repository_id => @repository.id,
                                :repository_git_config_key => {
                                  :key   => 'foo',
                                  :value => 0
                                }
          }.to_not change(RepositoryGitConfigKey, :count)
        end

        it "re-renders the :new template" do
          xhr :post, :create, :repository_id => @repository.id,
                              :repository_git_config_key => {
                                :key   => 'foo',
                                :value => 0
                              }
          expect(response).to render_template(:create)
        end
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        xhr :post, :create, :repository_id => @repository.id,
                            :repository_git_config_key => {
                              :key   => 'foo.bar2',
                              :value => 0
                            }
        expect(response.status).to eq 403
      end
    end
  end


  describe "GET #edit" do
    context "with sufficient permissions" do
      before(:each){ set_admin_session }

      context "with existing git_config_key" do
        it "assigns the requested git_config_key to @git_config_key" do
          get :edit, :repository_id => @repository.id, :id => @git_config_key.id
          expect(assigns(:git_config_key)).to eq @git_config_key
        end

        it "renders the :edit template" do
          get :edit, :repository_id => @repository.id, :id => @git_config_key.id
          expect(response).to render_template(:edit)
        end
      end

      context "with non-existing git_config_key" do
        it "renders 404" do
          get :edit, :repository_id => @repository.id, :id => 100
          expect(response.status).to eq 404
        end
      end

      context "with non-matching repository" do
        it "renders 404" do
          get :edit, :repository_id => @repository2.id, :id => @git_config_key.id
          expect(response.status).to eq 404
        end
      end

      context "with non-existing repository" do
        it "renders 404" do
          get :edit, :repository_id => 12345, :id => @git_config_key.id
          expect(response.status).to eq 404
        end
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        get :edit, :repository_id => @repository.id, :id => @git_config_key.id
        expect(response.status).to eq 403
      end
    end
  end


  describe "PUT #update" do
    context "with sufficient permissions" do
      before(:each){ set_admin_session }

      context "with valid attributes" do
        before do
          xhr :put, :update, repository_id: @repository.id, id: @git_config_key.id,
                             repository_git_config_key: { key: 'foo.bar1', value: 1 }
        end

        it "located the requested @git_config_key" do
          expect(assigns(:git_config_key)).to eq @git_config_key
        end

        it "changes @git_config_key's attributes" do
          @git_config_key.reload
          expect(@git_config_key.value).to eq '1'
        end

        it "redirects to the repository page" do
          expect(response.status).to eq 200
        end
      end

      context "with invalid attributes" do
        before do
          xhr :put, :update, repository_id: @repository.id, id: @git_config_key.id,
                             repository_git_config_key: { key: 'foo', value: 1 }
        end

        it "located the requested @git_config_key" do
          expect(assigns(:git_config_key)).to eq @git_config_key
        end

        it "does not change @git_config_key's attributes" do
          @git_config_key.reload
          expect(@git_config_key.value).to eq 'bar'
        end

        it "re-renders the :edit template" do
          expect(response).to render_template(:update)
        end
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        xhr :put, :update, repository_id: @repository.id, id: @git_config_key.id,
                           repository_git_config_key: { key: 'foo.bar1', value: 1 }
        expect(response.status).to eq 403
      end
    end
  end


  describe 'DELETE destroy' do
    context "with sufficient permissions" do
      it "deletes the git_config_key" do
        set_admin_session
        git_config_key_delete = FactoryGirl.create(:repository_git_config_key, :repository_id => @repository.id)
        expect{
          delete :destroy, :repository_id => @repository.id, :id => git_config_key_delete.id, :format => 'js'
        }.to change(RepositoryGitConfigKey, :count).by(-1)
      end

      it "redirects to repositories#edit" do
        set_admin_session
        git_config_key_delete = FactoryGirl.create(:repository_git_config_key, :repository_id => @repository.id)
        delete :destroy, :repository_id => @repository.id, :id => git_config_key_delete.id, :format => 'js'
        expect(response.status).to eq 200
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        git_config_key_delete = FactoryGirl.create(:repository_git_config_key, :repository_id => @repository.id)
        delete :destroy, :repository_id => @repository.id, :id => git_config_key_delete.id, :format => 'js'
        expect(response.status).to eq 403
      end
    end
  end

end
