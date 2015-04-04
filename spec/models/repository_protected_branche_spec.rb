require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryProtectedBranche do

  def build_protected_branch(opts = {})
    build(:repository_protected_branche, opts)
  end


  describe "Valid RepositoryProtectedBranche creation" do
    before(:each) do
      @protected_branch = build_protected_branch(:path => 'devel', :permissions => 'RW', :user_list => %w(user1 user2))
    end

    subject { @protected_branch }

    ## Attributes
    it { should allow_mass_assignment_of(:path) }
    it { should allow_mass_assignment_of(:permissions) }
    it { should allow_mass_assignment_of(:position) }
    it { should allow_mass_assignment_of(:user_list) }

    ## Relations
    it { should belong_to(:repository) }

    ## Validations
    it { should be_valid }

    it { should validate_presence_of(:repository_id) }
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:permissions) }
    it { should validate_presence_of(:user_list) }

    it { should validate_uniqueness_of(:path).scoped_to([:permissions, :repository_id]) }

    it { should validate_inclusion_of(:permissions).in_array(%w(RW RW+)) }

    ## Serializations
    it { should serialize(:user_list) }
  end
end
