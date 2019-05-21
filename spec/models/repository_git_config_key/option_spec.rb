require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe RepositoryGitConfigKey::Option do
  before(:each) do
    @git_config_key = build(:repository_git_option_key)
  end

  subject { @git_config_key }

  ## Validations
  it { should be_valid }
  it { should validate_presence_of(:key) }
  it { should validate_uniqueness_of(:key).scoped_to(:repository_id) }
  it { should allow_value('hookfoo', 'hookfoo.foo', 'hookfoo.foo.bar').for(:key) }


  context 'when key is updated' do
    before do
      @git_config_key.save
      @git_config_key.key = 'hookbar.foo'
      @git_config_key.save
    end

    it { should be_valid }
  end
end
