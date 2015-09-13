require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GoRedirectorController do

  def check_response_with_smart_http(repository, status:)
    enable_smart_http(repository)
    yield
    call_page(repository, status: status)
  end


  def check_response_without_smart_http(repository, status:)
    disable_smart_http(repository)
    yield
    call_page(repository, status: status)
  end


  def call_page(repository, status:)
    get :index, repo_path: repository.redmine_repository_path
    expect(response.status).to eq status
  end


  describe "GET #index" do
    context "when project is public" do
      let(:project){ FactoryGirl.create(:project, is_public: true) }
      let(:repository){ create_git_repository(project) }
      let(:anonymous_user){ create_anonymous_user }

      context "and SmartHTTP is enabled" do
        it "renders 200" do
          check_response_with_smart_http(repository, status: 200) { set_session_user(anonymous_user) }
        end
      end

      context "and SmartHTTP is disabled" do
        it "renders 403" do
          check_response_without_smart_http(repository, status: 403) { set_session_user(anonymous_user) }
        end
      end
    end

    context "when project is private" do
      let(:project){ FactoryGirl.create(:project, is_public: false) }
      let(:repository){ create_git_repository(project) }
      let(:anonymous_user){ create_anonymous_user }

      context "and SmartHTTP is enabled" do
        it "renders 403" do
          check_response_with_smart_http(repository, status: 403) { set_session_user(anonymous_user) }
        end

        context "when repository is public" do
          it "renders 200" do
            enable_public_repo(repository)
            check_response_with_smart_http(repository, status: 200) { set_session_user(anonymous_user) }
          end
        end
      end

      context "and SmartHTTP is disabled" do
        it "renders 403" do
          check_response_without_smart_http(repository, status: 403) { set_session_user(anonymous_user) }
        end
      end
    end
  end

end
