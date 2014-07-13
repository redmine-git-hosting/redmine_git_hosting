require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitConfigKeysController do

  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_git_config_keys"
  end


  before(:all) do
    @project        = FactoryGirl.create(:project)
    @repository     = FactoryGirl.create(:repository_git, :project_id => @project.id)
    @git_config_key = FactoryGirl.create(:repository_git_config_key, :repository_id => @repository.id)
    @user           = FactoryGirl.create(:user, :admin => true)

    @repository2    = FactoryGirl.create(:repository_git, :project_id => @project.id, :identifier => 'gck-test')
  end


  describe "GET #index" do
    before do
      request.session[:user_id] = @user.id
      get :index, :repository_id => @repository.id
    end

    it "populates an array of repository_git_config_keys" do
      expect(assigns(:repository_git_config_keys)).to eq [@git_config_key]
    end

    it "renders the :index view" do
      expect(response).to render_template(:index)
    end
  end


  describe "GET #show" do
    before do
      request.session[:user_id] = @user.id
      get :show, :repository_id => @repository.id, :id => @git_config_key.id
    end

    it "renders 404" do
      expect(response.status).to eq 404
    end
  end


  describe "GET #new" do
    before do
      request.session[:user_id] = @user.id
      get :new, :repository_id => @repository.id
    end

    it "assigns a new RepositoryGitConfigKey to @git_config_key" do
      expect(assigns(:git_config_key)).to be_an_instance_of(RepositoryGitConfigKey)
    end

    it "renders the :new template" do
      expect(response).to render_template(:new)
    end
  end


  describe "POST #create" do
    context "with valid attributes" do
      before do
        request.session[:user_id] = @user.id
      end

      it "saves the new git_config_key in the database" do
        expect{
          post :create, :repository_id => @repository.id,
                        :repository_git_config_key => {
                          :key   => 'foo.bar1',
                          :value => 0
                        }
        }.to change(RepositoryGitConfigKey, :count).by(1)
      end

      it "redirects to the repository page" do
        post :create, :repository_id => @repository.id,
                      :repository_git_config_key => {
                        :key   => 'foo.bar2',
                        :value => 0
                      }
        expect(response).to redirect_to(success_url)
      end
    end

    context "with invalid attributes" do
      before do
        request.session[:user_id] = @user.id
      end

      it "does not save the new post_receive_url in the database" do
        expect{
          post :create, :repository_id => @repository.id,
                        :repository_git_config_key => {
                          :key   => 'foo',
                          :value => 0
                        }
        }.to_not change(RepositoryGitConfigKey, :count)
      end

      it "re-renders the :new template" do
        post :create, :repository_id => @repository.id,
                      :repository_git_config_key => {
                        :key   => 'foo',
                        :value => 0
                      }
        expect(response).to render_template(:new)
      end
    end
  end


  describe "GET #edit" do
    context "with existing git_config_key" do
      before do
        request.session[:user_id] = @user.id
        get :edit, :repository_id => @repository.id, :id => @git_config_key.id
      end

      it "assigns the requested git_config_key to @git_config_key" do
        expect(assigns(:git_config_key)).to eq @git_config_key
      end

      it "renders the :edit template" do
        expect(response).to render_template(:edit)
      end
    end

    context "with non-existing git_config_key" do
      before do
        request.session[:user_id] = @user.id
        get :edit, :repository_id => @repository.id, :id => 100
      end

      it "renders 404" do
        expect(response.status).to eq 404
      end
    end

    context "with non-matching repository" do
      before do
        request.session[:user_id] = @user.id
        get :edit, :repository_id => @repository2.id, :id => @git_config_key.id
      end

      it "renders 403" do
        expect(response.status).to eq 403
      end
    end

    context "with unsufficient permissions" do
      before do
        request.session[:user_id] = FactoryGirl.create(:user).id
        get :edit, :repository_id => @repository.id, :id => @git_config_key.id
      end

      it "renders 403" do
        expect(response.status).to eq 403
      end
    end
  end


  describe "PUT #update" do
    before do
      request.session[:user_id] = @user.id
    end

    context "with valid attributes" do
      before do
        put :update, :repository_id => @repository.id,
                     :id => @git_config_key.id,
                     :repository_git_config_key => {
                        :key   => 'foo.bar1',
                        :value => 1
                     }
      end

      it "located the requested @git_config_key" do
        expect(assigns(:git_config_key)).to eq @git_config_key
      end

      it "changes @git_config_key's attributes" do
        @git_config_key.reload
        expect(@git_config_key.value).to eq '1'
      end

      it "redirects to the repository page" do
        expect(response).to redirect_to success_url
      end
    end

    context "with invalid attributes" do
      before do
        put :update, :repository_id => @repository.id,
                     :id => @git_config_key.id,
                     :repository_git_config_key => {
                        :key   => 'foo',
                        :value => 1
                     }
      end

      it "located the requested @git_config_key" do
        expect(assigns(:git_config_key)).to eq @git_config_key
      end

      it "does not change @git_config_key's attributes" do
        @git_config_key.reload
        expect(@git_config_key.value).to eq 'bar'
      end

      it "re-renders the :edit template" do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE destroy' do
    before :each do
      request.session[:user_id] = @user.id
      @git_config_key_delete = FactoryGirl.create(:repository_git_config_key, :repository_id => @repository.id)
    end

    it "deletes the git_config_key" do
      expect{
        delete :destroy, :repository_id => @repository.id, :id => @git_config_key_delete.id, :format => 'js'
      }.to change(RepositoryGitConfigKey, :count).by(-1)
    end

    it "redirects to repositories#edit" do
      delete :destroy, :repository_id => @repository.id, :id => @git_config_key_delete.id, :format => 'js'
      expect(response.status).to eq 200
    end
  end
end
