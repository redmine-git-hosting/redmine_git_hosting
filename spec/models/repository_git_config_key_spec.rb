require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitConfigKey do

  before do
    repository_git  = FactoryGirl.create(:repository_git)
    @git_config_key = FactoryGirl.build(:repository_git_config_key, repository_id: repository_git.id)
  end

  subject { @git_config_key }

  it { should respond_to(:repository) }
  it { should respond_to(:key) }
  it { should respond_to(:value) }

  it { should be_valid }

  ## Test presence validation
  describe "when repository_id is not present" do
    before { @git_config_key.repository_id = "" }
    it { should_not be_valid }
  end

  describe "when key is not present" do
    before { @git_config_key.key = "" }
    it { should_not be_valid }
  end

  describe "when value is not present" do
    before { @git_config_key.value = "" }
    it { should_not be_valid }
  end


  ## Test format validation
  describe "when key is valid" do
    it "should be valid" do
      git_config_keys = [
        'hookfoo.foo',
        'hookfoo.foo.bar'
      ]

      git_config_keys.each do |valid_config_key|
        @git_config_key.key = valid_config_key
        expect(@git_config_key).to be_valid
      end
    end
  end

  describe "when key is invalid" do
    it "should be invalid" do
      git_config_keys = [
        'hookfoo',
      ]

      git_config_keys.each do |invalid_config_key|
        @git_config_key.key = invalid_config_key
        expect(@git_config_key).not_to be_valid
      end
    end
  end

  describe "when key is updated" do
    before do
      @git_config_key.save
      @git_config_key.key = 'hookbar.foo'
      @git_config_key.save
    end

    it { expect(@git_config_key).to be_valid }
  end


  ## Test uniqueness validation
  describe "when key is already taken" do
    before do
      @git_config_key.save
      @git_config_key_with_same_key = @git_config_key.dup
      @git_config_key_with_same_key.save
    end

    it { expect(@git_config_key_with_same_key).not_to be_valid }
  end
end
