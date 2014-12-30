require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitNotification do

  VALID_MAIL   = ['user@foo.COM', 'A_US-ER@f.b.org', 'frst.lst@foo.jp', 'a+b@baz.cn']
  INVALID_MAIL = ['user@foo,com', 'user_at_foo.org', 'example.user@foo.', 'foo@bar_baz.com', 'foo@bar+baz.com', 'foo@bar..com']

  describe "Valid RepositoryGitNotification creation" do
    before(:each) do
      @git_notification = build(:repository_git_notification)
    end

    subject { @git_notification }

    ## Attributes
    it { should allow_mass_assignment_of(:prefix) }
    it { should allow_mass_assignment_of(:sender_address) }
    it { should allow_mass_assignment_of(:include_list) }
    it { should allow_mass_assignment_of(:exclude_list) }

    ## Relations
    it { should belong_to(:repository) }

    ## Validations
    it { should be_valid }

    it { should validate_presence_of(:repository_id) }

    it { should validate_uniqueness_of(:repository_id) }

    it { should allow_value(*VALID_MAIL).for(:sender_address) }

    it { should_not allow_value(*INVALID_MAIL).for(:sender_address) }

    ## Serializations
    it { should serialize(:include_list) }
    it { should serialize(:exclude_list) }

    ## Attributes content
    it { expect(@git_notification.prefix).to eq "[TEST PROJECT]" }
    it { expect(@git_notification.sender_address).to eq "redmine@example.com" }
    it { expect(@git_notification.include_list).to eq ['foo@bar.com', 'bar@foo.com'] }
    it { expect(@git_notification.exclude_list).to eq ['far@boo.com', 'boo@far.com'] }

    context "when include_list contains emails with valid format" do
      before { @git_notification.include_list = VALID_MAIL }
      it "should be valid" do
        expect(@git_notification).to be_valid
      end
    end

    context "when include_list contains emails with invalid format" do
      before { @git_notification.include_list = INVALID_MAIL }
      it "should be valid" do
        expect(@git_notification).not_to be_valid
      end
    end

    context "when exclude_list contains emails with valid format" do
      before { @git_notification.exclude_list = VALID_MAIL }
      it "should be valid" do
        expect(@git_notification).to be_valid
      end
    end

    context "when exclude_list contains emails with invalid format" do
      before { @git_notification.exclude_list = INVALID_MAIL }
      it "should be valid" do
        expect(@git_notification).not_to be_valid
      end
    end

    describe "when emails is in both list" do
      addresses = [
        'user@foo.COM',
        'A_US-ER@f.b.org',
        'frst.lst@foo.jp',
        'a+b@baz.cn'
      ]

      before do
        @git_notification.include_list = addresses
        @git_notification.exclude_list = addresses
      end

      it "should be invalid" do
        expect(@git_notification).not_to be_valid
      end
    end
  end
end
