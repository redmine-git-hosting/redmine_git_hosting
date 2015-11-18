require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  let(:user) { build(:user) }

  subject { user }

  it { should have_many(:protected_branches_members).dependent(:destroy) }
  it { should have_many(:protected_branches).through(:protected_branches_members) }

  describe '#gitolite_identifier' do
    it 'should return the gitolite_identifier' do
      user = build(:user, id: 12)
      expect(user.gitolite_identifier).to eq 'redmine_user46_12'
    end
  end
end
