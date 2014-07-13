require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryDeploymentCredentialsController do

  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_deployment_credentials"
  end

  DEPLOY_KEY2 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz0pLXcQWS4gLUimUSLwDOvEmQF8l8EKoj0LjxOyM3y2dpLsn0aiqS0ecA0G/ROomaawop8EZGFetoJKJM468OZlx2aKoQemzvFIq0Mn1ZhcrlA1alAsDYqzZI8iHO4JIS3YbeLLkVGAlYA+bmA5enXN9mGhC9cgoMC79EZiLD9XvOw4iXDjqXaCzFZHU1shMWwaJfpyxBm+Mxs2vtZzwETDqeu9rohNMl60dODf6+JoXYiahP+B+P2iKlL7ORb1YsAH/4ZMsVgRckj8snb4uc3XgwLRNNw+oB78ApZGr0j3Zc32U9rpmulbHIroWO07OV4Xsplnu8lhGvfodA2gjb nicolas@tchoum'
  DEPLOY_KEY3 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoG/GwPjzEq1Ybph3J+DX8nd3kQM4hYP378rPJLI9RGyUnd1Zs7/T8uu27fgsY10v4sFcsQwBMrZoR/2XchjUTj0e4ai6asVSezhJCLSTG/TQtXzsdxyr+5hm9vQia97IMNhCL+KOW5pz5ZrhV9abR1vSlAAlk919mRD7Nmyo8Qg0g0iYHWsTddYDEMIelCLQTPahuJJb0bOcCZvDVR7Q87vSMiIWTajDhfJYauvP0tbFV7R1VTjKCIv/cSySbrAtTZigQ5Ul1ILkMaETsKS9p9YHNeWhLlHvYDGa+eb4+rfiM2RMxC98wePqINT46EFw0vPiLW+ukqD/5b2cb+7OP nicolas@tchoum'

  before(:all) do
    @project        = FactoryGirl.create(:project)
    @repository     = FactoryGirl.create(:repository_git, :project_id => @project.id)
    @user           = FactoryGirl.create(:user, :admin => true)

    @credential     = FactoryGirl.create(:repository_deployment_credential,
      :repository_id          => @repository.id,
      :user_id                => @user.id,
      :gitolite_public_key_id => FactoryGirl.create(:gitolite_public_key, :user_id => @user.id, :key_type => 1, :title => 'foo1', :key => DEPLOY_KEY2).id
    )

    @repository2    = FactoryGirl.create(:repository_git, :project_id => @project.id, :identifier => 'credential-test')
  end


  describe "GET #index" do
    before do
      request.session[:user_id] = @user.id
      get :index, :repository_id => @repository.id
    end

    it "populates an array of repository_deployment_credentials" do
      expect(assigns(:repository_deployment_credentials)).to eq [@credential]
    end

    it "renders the :index view" do
      expect(response).to render_template(:index)
    end
  end


  describe "GET #show" do
    before do
      request.session[:user_id] = @user.id
      get :show, :repository_id => @repository.id, :id => @credential.id
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

    it "assigns a new RepositoryDeploymentCredential to @credential" do
      expect(assigns(:credential)).to be_an_instance_of(RepositoryDeploymentCredential)
    end

    it "renders the :new template" do
      expect(response).to render_template(:new)
    end
  end


  describe "POST #create" do
    context "with valid attributes" do
      before do
        request.session[:user_id] = @user.id
        @public_key = FactoryGirl.create(:gitolite_public_key, :user_id => @user.id, :key_type => 1, :title => 'foo11', :key => DEPLOY_KEY3)
      end

      it "saves the new credential in the database" do
        expect{
          post :create, :repository_id => @repository.id,
                        :repository_deployment_credential => {
                          :gitolite_public_key_id => @public_key.id,
                          :perm => 'RW+'
                        }
        }.to change(RepositoryDeploymentCredential, :count).by(1)
      end

      it "redirects to the repository page" do
        post :create, :repository_id => @repository.id,
                      :repository_deployment_credential => {
                        :gitolite_public_key_id => @public_key.id,
                        :perm => 'RW+'
                      }
        expect(response).to redirect_to(success_url)
      end
    end

    context "with invalid attributes" do
      before do
        request.session[:user_id] = @user.id
        @public_key = FactoryGirl.create(:gitolite_public_key, :user_id => @user.id, :key_type => 1, :title => 'foo12', :key => DEPLOY_KEY3)
      end

      it "does not save the new credential in the database" do
        expect{
          post :create, :repository_id => @repository.id,
                        :repository_deployment_credential => {
                          :gitolite_public_key_id => @public_key.id,
                          :perm => 'RW'
                        }
        }.to_not change(RepositoryDeploymentCredential, :count)
      end

      it "re-renders the :new template" do
        post :create, :repository_id => @repository.id,
                      :repository_deployment_credential => {
                        :gitolite_public_key_id => @public_key.id,
                        :perm => 'RW'
                      }
        expect(response).to render_template(:new)
      end
    end
  end


  describe "GET #edit" do
    context "with existing credential" do
      before do
        request.session[:user_id] = @user.id
        get :edit, :repository_id => @repository.id, :id => @credential.id
      end

      it "assigns the requested credential to @credential" do
        expect(assigns(:credential)).to eq @credential
      end

      it "renders the :edit template" do
        expect(response).to render_template(:edit)
      end
    end

    context "with non-existing credential" do
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
        get :edit, :repository_id => @repository2.id, :id => @credential.id
      end

      it "renders 403" do
        expect(response.status).to eq 403
      end
    end

    context "with unsufficient permissions" do
      before do
        request.session[:user_id] = FactoryGirl.create(:user).id
        get :edit, :repository_id => @repository.id, :id => @credential.id
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
                     :id => @credential.id,
                     :repository_deployment_credential => {
                        :perm => 'R'
                     }
      end

      it "located the requested @credential" do
        expect(assigns(:credential)).to eq @credential
      end

      it "changes @credential's attributes" do
        @credential.reload
        expect(@credential.perm).to eq 'R'
      end

      it "redirects to the repository page" do
        expect(response).to redirect_to success_url
      end
    end

    context "with invalid attributes" do
      before do
        put :update, :repository_id => @repository.id,
                     :id => @credential.id,
                     :repository_deployment_credential => {
                        :perm => 'RW',
                     }
      end

      it "located the requested @credential" do
        expect(assigns(:credential)).to eq @credential
      end

      it "does not change @credential's attributes" do
        @credential.reload
        expect(@credential.perm).to eq 'RW+'
      end

      it "re-renders the :edit template" do
        expect(response).to render_template(:edit)
      end
    end
  end


  describe 'DELETE destroy' do
    before :each do
      request.session[:user_id] = @user.id

      @credential_delete = FactoryGirl.create(:repository_deployment_credential,
        :repository_id          => @repository.id,
        :user_id                => @user.id,
        :gitolite_public_key_id => FactoryGirl.create(:gitolite_public_key, :user_id => @user.id, :key_type => 1, :title => 'foo2', :key => DEPLOY_KEY3).id
      )
    end

    it "deletes the git_config_key" do
      expect{
        delete :destroy, :repository_id => @repository.id, :id => @credential_delete.id, :format => 'js'
      }.to change(RepositoryDeploymentCredential, :count).by(-1)
    end

    it "redirects to repositories#edit" do
      delete :destroy, :repository_id => @repository.id, :id => @credential_delete.id, :format => 'js'
      expect(response.status).to eq 200
    end
  end

end
