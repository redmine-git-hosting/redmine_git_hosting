require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitConfigKey do

  describe "Valid RepositoryGitConfigKey creation" do
    before(:each) do
      @git_config_key = build(:repository_git_config_key)
    end

    subject { @git_config_key }

    ## Attributes
    it { should allow_mass_assignment_of(:key) }
    it { should allow_mass_assignment_of(:value) }

    ## Relations
    it { should belong_to(:repository) }

    ## Validations
    it { should be_valid }

    it { should validate_presence_of(:repository_id) }
    it { should validate_presence_of(:key) }
    it { should validate_presence_of(:value) }

    it { should validate_uniqueness_of(:key).scoped_to(:repository_id) }

    it {
      should allow_value('hookfoo.foo', 'hookfoo.foo.bar').
      for(:key)
    }

    it {
      should_not allow_value('hookfoo').
      for(:key)
    }

    context "when key is updated" do
      before do
        @git_config_key.save
        @git_config_key.key = 'hookbar.foo'
        @git_config_key.save
      end

      it { should be_valid }
    end
  end
end
