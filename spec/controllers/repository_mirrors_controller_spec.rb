require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryMirrorsController do

  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_mirrors"
  end

  before(:all) do
    @project        = FactoryGirl.create(:project)
    @repository     = FactoryGirl.create(:repository_gitolite, :project_id => @project.id)
    @mirror         = FactoryGirl.create(:repository_mirror, :repository_id => @repository.id)
    @no_right_user  = FactoryGirl.create(:user)
    @repository2    = FactoryGirl.create(:repository_gitolite, :project_id => @project.id, :identifier => 'mirror-test')
    @member_user    = create_user_with_permissions(@project, permissions: [:manage_repository, :create_repository_mirrors, :view_repository_mirrors, :edit_repository_mirrors, :push_repository_mirrors])
  end


  def set_admin_session
    request.session[:user_id] = @member_user.id
  end


  def set_no_right_session
    request.session[:user_id] = @no_right_user.id
  end


  describe "GET #index" do
    context "with sufficient permissions" do
      before(:each) { set_admin_session }

      it "populates an array of mirrors" do
        get :index, :repository_id => @repository.id
        expect(assigns(:repository_mirrors)).to eq [@mirror]
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
        get :show, :repository_id => @repository.id, :id => @mirror.id, :format => 'json', :key => @member_user.api_key
        expect(response.status).to eq 200
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        get :show, :repository_id => @repository.id, :id => @mirror.id, :format => 'json', :key => @no_right_user.api_key
        expect(response.status).to eq 403
      end
    end
  end


  describe "GET #new" do
    context "with sufficient permissions" do
      before(:each) { set_admin_session }

      it "assigns a new RepositoryMirror to @mirror" do
        get :new, :repository_id => @repository.id
        expect(assigns(:mirror)).to be_an_instance_of(RepositoryMirror)
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
      before(:each) { set_admin_session }

      context "with valid attributes" do
        it "saves the new mirror in the database" do
          expect{
            xhr :post, :create, :repository_id => @repository.id,
                                :repository_mirror => {
                                  :url => 'ssh://git@redmine.example.org/project1/project2/project3/project4.git',
                                  :push_mode => 0
                                }
          }.to change(RepositoryMirror, :count).by(1)
        end

        it "redirects to the repository page" do
          xhr :post, :create, :repository_id => @repository.id,
                              :repository_mirror => {
                                :url => 'ssh://git@redmine.example.org/project1/project2/project3/project4/repo1.git',
                                :push_mode => 0
                              }
          expect(response.status).to eq 200
        end
      end

      context "with invalid attributes" do
        it "does not save the new mirror in the database" do
          expect{
            xhr :post, :create, :repository_id => @repository.id,
                                :repository_mirror => {
                                  :url => 'git@redmine.example.org/project1/project2/project3/project4.git',
                                  :push_mode => 0
                                }
          }.to_not change(RepositoryMirror, :count)
        end

        it "re-renders the :new template" do
          xhr :post, :create, :repository_id => @repository.id,
                              :repository_mirror => {
                                :url => 'git@redmine.example.org/project1/project2/project3/project4.git',
                                :push_mode => 0
                              }
          expect(response).to render_template(:create)
        end
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        xhr :post, :create, :repository_id => @repository.id,
                            :repository_mirror => {
                              :url => 'ssh://git@redmine.example.org/project1/project2/project3/project4/repo1.git',
                              :push_mode => 0
                            }
        expect(response.status).to eq 403
      end
    end
  end


  describe "GET #edit" do
    context "with sufficient permissions" do
      before(:each) { set_admin_session }

      context "with existing mirror" do
        it "assigns the requested mirror to @mirror" do
          get :edit, :repository_id => @repository.id, :id => @mirror.id
          expect(assigns(:mirror)).to eq @mirror
        end

        it "renders the :edit template" do
          get :edit, :repository_id => @repository.id, :id => @mirror.id
          expect(response).to render_template(:edit)
        end
      end

      context "with non-existing mirror" do
        it "renders 404" do
          get :edit, :repository_id => @repository.id, :id => 100
          expect(response.status).to eq 404
        end
      end

      context "with non-matching repository" do
        it "renders 404" do
          get :edit, :repository_id => @repository2.id, :id => @mirror.id
          expect(response.status).to eq 404
        end
      end

      context "with non-existing repository" do
        it "renders 404" do
          get :edit, :repository_id => 12345, :id => @mirror.id
          expect(response.status).to eq 404
        end
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        get :edit, :repository_id => @repository.id, :id => @mirror.id
        expect(response.status).to eq 403
      end
    end
  end


  describe "PUT #update" do
    context "with sufficient permissions" do
      before(:each) { set_admin_session }

      context "with valid attributes" do
        before do
          xhr :put, :update, repository_id: @repository.id, id: @mirror.id,
                       repository_mirror: { url: 'ssh://git@redmine.example.org/project1/project2/project3/project4.git' }
        end

        it "located the requested @mirror" do
          expect(assigns(:mirror)).to eq @mirror
        end

        it "changes @mirror's attributes" do
          @mirror.reload
          expect(@mirror.url).to eq 'ssh://git@redmine.example.org/project1/project2/project3/project4.git'
        end

        it "redirects to the repository page" do
          expect(response.status).to eq 200
        end
      end

      context "with invalid attributes" do
        before do
          xhr :put, :update, repository_id: @repository.id, id: @mirror.id,
                       repository_mirror: { url: 'git@redmine.example.org/project1/project2/project3/project4.git' }
        end

        it "located the requested @mirror" do
          expect(assigns(:mirror)).to eq @mirror
        end

        it "does not change @mirror's attributes" do
          @mirror.reload
          expect(@mirror.url).to eq 'ssh://host.xz/path/to/repo1.git'
        end

        it "re-renders the :edit template" do
          expect(response).to render_template(:update)
        end
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        xhr :put, :update, repository_id: @repository.id, id: @mirror.id,
                     repository_mirror: { url: 'ssh://git@redmine.example.org/project1/project2/project3/project4.git' }
        expect(response.status).to eq 403
      end
    end
  end


  describe 'DELETE destroy' do
    context "with sufficient permissions" do
      before(:each) { set_admin_session }

      it "deletes the mirror" do
        mirror_delete = FactoryGirl.create(:repository_mirror, :repository_id => @repository.id)
        expect{
          delete :destroy, :repository_id => @repository.id, :id => mirror_delete.id, :format => 'js'
        }.to change(RepositoryMirror, :count).by(-1)
      end

      it "redirects to repositories#edit" do
        mirror_delete = FactoryGirl.create(:repository_mirror, :repository_id => @repository.id)
        delete :destroy, :repository_id => @repository.id, :id => mirror_delete.id, :format => 'js'
        expect(response.status).to eq 200
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        mirror_delete = FactoryGirl.create(:repository_mirror, :repository_id => @repository.id)
        delete :destroy, :repository_id => @repository.id, :id => mirror_delete.id, :format => 'js'
        expect(response.status).to eq 403
      end
    end
  end


  describe "GET #push" do
    context "with sufficient permissions" do
      it "renders the :push view" do
        set_admin_session
        get :push, :repository_id => @repository.id, :id => @mirror.id
        expect(response).to render_template(:push)
      end
    end

    context "with unsufficient permissions" do
      it "renders 403" do
        set_no_right_session
        get :push, :repository_id => @repository.id, :id => @mirror.id
        expect(response.status).to eq 403
      end
    end
  end

end
