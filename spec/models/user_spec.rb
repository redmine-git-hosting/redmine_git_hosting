require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  before(:each) do
    @user = create(:user)
  end

  subject { @user }

  it { should be_valid }

  it { should respond_to(:gitolite_identifier) }

  it "has a gitolite_identifier" do
    expect(@user.gitolite_identifier).to match(/redmine_user\d+_\d+/)
  end
end
