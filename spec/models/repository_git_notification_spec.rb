require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitNotification do

  before do
    repository_git = FactoryGirl.create(:repository_git)
    @git_notification = FactoryGirl.build(:repository_git_notification, repository_id: repository_git.id)
  end

  subject { @git_notification }

  it { should respond_to(:repository) }
  it { should respond_to(:include_list) }
  it { should respond_to(:exclude_list) }
  it { should respond_to(:prefix) }
  it { should respond_to(:sender_address) }

  it { should be_valid }

  it { expect(@git_notification.prefix).to eq "[TEST PROJECT]" }
  it { expect(@git_notification.sender_address).to eq "redmine@example.com" }
  it { expect(@git_notification.include_list).to eq [ 'foo@bar.com', 'bar@foo.com'] }
  it { expect(@git_notification.exclude_list).to eq [ 'far@boo.com', 'boo@far.com'] }


  ## Test presence validation
  describe "when repository_id is not present" do
    before { @git_notification.repository_id = "" }
    it { should_not be_valid }
  end

  describe "when sender address is not present" do
    before { @git_notification.sender_address = "" }
    it { should be_valid }
  end

  describe "when include_list is not present" do
    before { @git_notification.include_list = [] }
    it { should be_valid }
  end

  describe "when exclude_list is not present" do
    before { @git_notification.exclude_list = [] }
    it { should be_valid }
  end


  ## Test format validation
  describe "when sender address format is valid" do
    it "should be valid" do
      addresses = [
        'user@foo.COM',
        'A_US-ER@f.b.org',
        'frst.lst@foo.jp',
        'a+b@baz.cn'
      ]

      addresses.each do |valid_address|
        @git_notification.sender_address = valid_address
        expect(@git_notification).to be_valid
      end
    end
  end

  describe "when sender address format is invalid" do
    it "should be invalid" do
      addresses = [
        'user@foo,com',
        'user_at_foo.org',
        'example.user@foo.',
        'foo@bar_baz.com',
        'foo@bar+baz.com',
        'foo@bar..com'
      ]

      addresses.each do |invalid_address|
        @git_notification.sender_address = invalid_address
        expect(@git_notification).not_to be_valid
      end
    end
  end


  describe "when include_list contains emails with valid format" do
    it "should be valid" do
      addresses = [
        'user@foo.COM',
        'A_US-ER@f.b.org',
        'frst.lst@foo.jp',
        'a+b@baz.cn'
      ]

      @git_notification.include_list = addresses
      expect(@git_notification).to be_valid
    end
  end

  describe "when include_list contains emails with invalid format" do
    it "should be invalid" do
      addresses = [
        'user@foo,com',
        'user_at_foo.org',
        'example.user@foo.',
        'foo@bar_baz.com',
        'foo@bar+baz.com',
        'foo@bar..com'
      ]

      @git_notification.include_list = addresses
      expect(@git_notification).not_to be_valid
    end
  end

  describe "when exclude_list contains emails with valid format" do
    it "should be valid" do
      addresses = [
        'user@foo.COM',
        'A_US-ER@f.b.org',
        'frst.lst@foo.jp',
        'a+b@baz.cn'
      ]

      @git_notification.exclude_list = addresses
      expect(@git_notification).to be_valid
    end
  end

  describe "when exclude_list contains emails with invalid format" do
    it "should be invalid" do
      addresses = [
        'user@foo,com',
        'user_at_foo.org',
        'example.user@foo.',
        'foo@bar_baz.com',
        'foo@bar+baz.com',
        'foo@bar..com'
      ]

      @git_notification.exclude_list = addresses
      expect(@git_notification).not_to be_valid
    end
  end

  describe "when emails is in both list" do
    it "should be invalid" do
      addresses = [
        'user@foo.COM',
        'A_US-ER@f.b.org',
        'frst.lst@foo.jp',
        'a+b@baz.cn'
      ]

      @git_notification.include_list = addresses
      @git_notification.exclude_list = addresses
      expect(@git_notification).not_to be_valid
    end
  end
end
