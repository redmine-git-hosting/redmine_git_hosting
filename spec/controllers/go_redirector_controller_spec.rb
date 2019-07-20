require File.expand_path('../spec_helper', __dir__)

describe GoRedirectorController do
  def check_response_with_smart_http(repository, opts = {})
    enable_go_url(repository)
    yield
    call_page(repository, opts[:status])
  end

  def check_response_without_smart_http(repository, opts = {})
    disable_go_url(repository)
    yield
    call_page(repository, opts[:status])
  end

  def call_page(repository, status)
    get :index, params: { repo_path: repository.redmine_repository_path }
    expect(response.status).to eq status
  end

  def enable_go_url(repository)
    repository.extra[:git_http] = true
    repository.extra[:git_go]   = true
    repository.extra.save!
  end

  def disable_go_url(repository)
    repository.extra[:git_http] = false
    repository.extra[:git_go]   = false
    repository.extra.save!
  end

  def enable_public_repo(repository)
    repository.extra[:public_repo] = true
    repository.extra.save!
  end

  describe 'GET #index' do
    context 'when project is public' do
      let(:project) { FactoryBot.create(:project, is_public: true) }
      let(:repository) { create_git_repository(project: project) }
      let(:anonymous_user) { create_anonymous_user }

      context 'and SmartHTTP is enabled' do
        it 'renders 200' do
          check_response_with_smart_http(repository, status: 200) { set_session_user(anonymous_user) }
        end
      end

      context 'and SmartHTTP is disabled' do
        it 'renders 403' do
          check_response_without_smart_http(repository, status: 403) { set_session_user(anonymous_user) }
        end
      end
    end

    context 'when project is private' do
      let(:project) { FactoryBot.create(:project, is_public: false) }
      let(:repository) { create_git_repository(project: project) }
      let(:anonymous_user) { create_anonymous_user }

      context 'and SmartHTTP is enabled' do
        it 'renders 403' do
          check_response_with_smart_http(repository, status: 403) { set_session_user(anonymous_user) }
        end

        context 'when repository is public' do
          it 'renders 200' do
            enable_public_repo(repository)
            check_response_with_smart_http(repository, status: 200) { set_session_user(anonymous_user) }
          end
        end
      end

      context 'and SmartHTTP is disabled' do
        it 'renders 403' do
          check_response_without_smart_http(repository, status: 403) { set_session_user(anonymous_user) }
        end
      end
    end
  end
end
