require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryProtectedBranche do

  def build_protected_branch(opts = {})
    build(:repository_protected_branche, opts)
  end


  describe "Valid RepositoryProtectedBranche creation" do
    before(:each) do
      @protected_branch = build_protected_branch(path: 'devel', permissions: 'RW')
    end

    subject { @protected_branch }

    ## Attributes
    it { should allow_mass_assignment_of(:path) }
    it { should allow_mass_assignment_of(:permissions) }
    it { should allow_mass_assignment_of(:position) }
    it { should allow_mass_assignment_of(:user_ids) }

    ## Relations
    it { should belong_to(:repository) }
    it { should have_many(:protected_branches_users).with_foreign_key(:protected_branch_id).dependent(:destroy) }
    it { should have_many(:users).through(:protected_branches_users) }

    ## Validations
    it { should be_valid }

    it { should validate_presence_of(:repository_id) }
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:permissions) }

    it { should validate_uniqueness_of(:path).scoped_to([:permissions, :repository_id]) }

    it { should validate_inclusion_of(:permissions).in_array(%w(RW RW+)) }
  end
end
