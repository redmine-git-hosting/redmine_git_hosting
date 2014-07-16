require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitExtra do

  def build_git_extra(opts = {})
    FactoryGirl.build(:repository_git_extra, opts)
  end

  describe "Valid RepositoryGitExtra creation" do
    before do
      @git_extra = build_git_extra
    end

    subject { @git_extra }

    ## Attributes
    it { should allow_mass_assignment_of(:git_http) }
    it { should allow_mass_assignment_of(:git_daemon) }
    it { should allow_mass_assignment_of(:git_notify) }
    it { should allow_mass_assignment_of(:default_branch) }
    it { should allow_mass_assignment_of(:protected_branch) }

    ## Relations
    it { should belong_to(:repository) }

    ## Validations
    # it { should be_valid }

    it { should validate_presence_of(:repository_id) }
    it { should validate_presence_of(:git_http) }
    it { should validate_presence_of(:default_branch) }
    it { should validate_presence_of(:key) }

    it { should validate_uniqueness_of(:repository_id) }

    it { should validate_numericality_of(:git_http) }

    it {
      should ensure_inclusion_of(:git_http).
      in_array(%w(0 1 2 3))
    }
  end

end
