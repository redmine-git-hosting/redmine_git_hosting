require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryMirror do

  MIRROR_URL = 'ssh://host.xz/path/to/repo.git'

  VALID_URLS = [
    'ssh://user@host.xz:2222/path/to/repo.git',
    'ssh://user@host.xz/path/to/repo.git',
    'ssh://user-name@long.host-domain.xz/path.git',
    'ssh://host.xz:2222/path/to/repo.git',
    'ssh://host.xz/path/to/repo.git',
    'ssh://user@host.xz/path/to/repo.git',
    'ssh://host.xz/path/to/repo.git',
    'ssh://user@host.xz/~user/path/to/repo.git',
    'ssh://host.xz/~user/path/to/repo.git',
    'ssh://user@host.xz/~/path/to/repo.git',
    'ssh://host.xz/~/path/to/repo.git',
    'ssh://host.xz/~/path.to/repo.git'
  ]


  def build_mirror(opts = {})
    build(:repository_mirror, opts)
  end


  describe "Valid RepositoryMirror creation" do
    before(:each) do
      @mirror = build(:repository_mirror)
    end

    subject { @mirror }

    ## Attributes
    it { should allow_mass_assignment_of(:url) }
    it { should allow_mass_assignment_of(:push_mode) }
    it { should allow_mass_assignment_of(:include_all_branches) }
    it { should allow_mass_assignment_of(:include_all_tags) }
    it { should allow_mass_assignment_of(:explicit_refspec) }
    it { should allow_mass_assignment_of(:active) }

    ## Relations
    it { should belong_to(:repository) }

    ## Validations
    it { should be_valid }

    it { should validate_presence_of(:repository_id) }
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:push_mode) }

    it { should validate_uniqueness_of(:url).scoped_to(:repository_id) }

    it { should allow_value(*VALID_URLS).for(:url) }

    it { should validate_numericality_of(:push_mode) }

    it { should validate_inclusion_of(:push_mode).in_array(%w(0 1 2)) }

    ## Attributes content
    it { expect(@mirror.active).to be true }
    it { expect(@mirror.include_all_branches).to be false }
    it { expect(@mirror.include_all_tags).to be false }
    it { expect(@mirror.explicit_refspec).to eq "" }
    it { expect(@mirror.push_mode).to eq 0 }
    it { expect(@mirror.push_mode).to be_a(Integer) }

    ## Test changes
    describe "when active is true" do
      before { @mirror.active = true }
      it "shoud be active" do
        expect(@mirror.active).to be true
      end
    end

    describe "when active is false" do
      before { @mirror.active = false }
      it "should be inactive" do
        expect(@mirror.active).to be false
      end
    end
  end


  describe "Invalid Mirror creation" do
    ## Test presence conflicts
    it "is invalid when include_all_branches && include_all_tags" do
      expect(build_mirror(:push_mode => 1, :include_all_branches => true, :include_all_tags => true)).not_to be_valid
    end

    it "is invalid when include_all_branches && explicit_refspec" do
      expect(build_mirror(:push_mode => 1, :include_all_branches => true, :explicit_refspec => 'devel')).not_to be_valid
    end

    ## Validate push mode : forced
    it "is invalid when push_mode forced without params" do
      expect(build_mirror(:push_mode => 1)).not_to be_valid
    end

    ## Validate push mode : fast_forward
    it "is invalid when push_mode fast_forward without params" do
      expect(build_mirror(:push_mode => 2)).not_to be_valid
    end

    ## Validate explicit_refspec
    it "is invalid when explicit_refspec is invalid" do
      expect(build_mirror(:push_mode => 1, :explicit_refspec => ':/devel')).not_to be_valid
    end
  end


  context "when many mirror are saved" do
    before do
      create(:repository_mirror, :active => true)
      create(:repository_mirror, :active => true)
      create(:repository_mirror, :active => false)
      create(:repository_mirror, :active => false)
    end

    it { expect(RepositoryMirror.active.length).to be == 3 }
    it { expect(RepositoryMirror.inactive.length).to be == 2 }
  end

end
