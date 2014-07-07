require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryPostReceiveUrlsController do

  def success_url
    "/repositories/#{@repository_git.id}/edit?tab=repository_post_receive_urls"
  end


  before(:all) do
    @project          = FactoryGirl.create(:project)
    @repository_git   = FactoryGirl.create(:repository, :project_id => @project.id)
    @post_receive_url = FactoryGirl.create(:repository_post_receive_url, :repository_id => @repository_git.id)
    @user             = FactoryGirl.create(:user, :admin => true)
  end


  describe "GET #index" do
    before do
      request.session[:user_id] = @user.id
      get :index, :repository_id => @repository_git.id
    end

    it "populates an array of post_receive_urls" do
      expect(assigns(:repository_post_receive_urls)).to eq [@post_receive_url]
    end

    it "renders the :index view" do
      expect(response).to render_template(:index)
    end
  end


  describe "GET #show" do
    before do
      request.session[:user_id] = @user.id
      get :show, :repository_id => @repository_git.id, :id => @post_receive_url.id
    end

    it "renders 404" do
      expect(response.status).to eq 404
    end
  end


  describe "GET #new" do
    before do
      request.session[:user_id] = @user.id
      get :new, :repository_id => @repository_git.id
    end

    it "assigns a new RepositoryPostReceiveUrl to @post_receive_url" do
      expect(assigns(:post_receive_url)).to be_an_instance_of(RepositoryPostReceiveUrl)
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

      it "saves the new post_receive_url in the database" do
        expect{
          post :create, :repository_id => @repository_git.id,
                        :repository_post_receive_url => {
                          :url  => 'http://example.com',
                          :mode => :github
                        }
        }.to change(RepositoryPostReceiveUrl, :count).by(1)
      end

      it "redirects to the repository page" do
        post :create, :repository_id => @repository_git.id,
                      :repository_post_receive_url => {
                        :url  => 'http://example2.com',
                        :mode => :github
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
          post :create, :repository_id => @repository_git.id,
                        :repository_post_receive_url => {
                          :url  => 'example.com',
                          :mode => :github
                        }
        }.to_not change(RepositoryPostReceiveUrl, :count)
      end

      it "re-renders the :new template" do
        post :create, :repository_id => @repository_git.id,
                      :repository_post_receive_url => {
                        :url  => 'example.com',
                        :mode => :github
                      }
        expect(response).to render_template(:new)
      end
    end
  end


  describe "GET #edit" do
    context "with existing post_receive_url" do
      before do
        request.session[:user_id] = @user.id
        get :edit, :repository_id => @repository_git.id, :id => @post_receive_url.id
      end

      it "assigns the requested post_receive_url to @post_receive_url" do
        expect(assigns(:post_receive_url)).to eq @post_receive_url
      end

      it "renders the :edit template" do
        expect(response).to render_template(:edit)
      end
    end

    context "with non-existing post_receive_url" do
      before do
        request.session[:user_id] = @user.id
        get :edit, :repository_id => @repository_git.id, :id => 100
      end

      it "renders 404" do
        expect(response.status).to eq 404
      end
    end

    context "with unsufficient permissions" do
      before do
        request.session[:user_id] = FactoryGirl.create(:user).id
        get :edit, :repository_id => @repository_git.id, :id => @post_receive_url.id
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
        put :update, :repository_id => @repository_git.id,
                     :id => @post_receive_url.id,
                     :repository_post_receive_url => {
                       :url => 'http://example.com/titi.php'
                     }
      end

      it "located the requested @post_receive_url" do
        expect(assigns(:post_receive_url)).to eq @post_receive_url
      end

      it "changes @post_receive_url's attributes" do
        @post_receive_url.reload
        expect(@post_receive_url.url).to eq 'http://example.com/titi.php'
      end

      it "redirects to the repository page" do
        expect(response).to redirect_to success_url
      end
    end

    context "with invalid attributes" do
      before do
        put :update, :repository_id => @repository_git.id,
                     :id => @post_receive_url.id,
                     :repository_post_receive_url => {
                       :url => 'example.com'
                     }
      end

      it "located the requested @post_receive_url" do
        expect(assigns(:post_receive_url)).to eq @post_receive_url
      end

      it "does not change @post_receive_url's attributes" do
        @post_receive_url.reload
        expect(@post_receive_url.url).to eq 'http://example.com/toto1.php'
      end

      it "re-renders the :edit template" do
        expect(response).to render_template(:edit)
      end
    end
  end


  describe 'DELETE destroy' do
    before :each do
      request.session[:user_id] = @user.id
      @post_receive_url = FactoryGirl.create(:repository_post_receive_url, :repository_id => @repository_git.id)
    end

    it "deletes the post_receive_url" do
      expect{
        delete :destroy, :repository_id => @repository_git.id, :id => @post_receive_url.id, :format => 'js'
      }.to change(RepositoryPostReceiveUrl, :count).by(-1)
    end

    it "redirects to repositories#edit" do
      delete :destroy, :repository_id => @repository_git.id, :id => @post_receive_url.id, :format => 'js'
      expect(response.status).to eq 200
    end
  end
end
