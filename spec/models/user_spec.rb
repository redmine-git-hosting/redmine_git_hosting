require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  before(:each) do
    @user = build(:user)
  end

  subject { @user }

  it { should have_many(:protected_branches_members).dependent(:destroy) }
  it { should have_many(:protected_branches).through(:protected_branches_members) }

  it 'has a gitolite_identifier' do
    user = create(:user)
    expect(user.gitolite_identifier).to match(/redmine_user\d+_\d+/)
  end
end
