require File.expand_path('../spec_helper', __dir__)

describe User do
  let(:user) { build(:user) }

  it { is_expected.to have_many(:protected_branches_members).dependent(:destroy) }
  it { is_expected.to have_many(:protected_branches).through(:protected_branches_members) }

  describe '#gitolite_identifier' do
    it 'return the gitolite_identifier' do
      user = build(:user, login: 'adam.30', id: 12)
      expect(user.gitolite_identifier).to eq 'redmine_adam_30_12'
    end
  end
end
