require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GitolitePublicKey do
  SSH_KEY_0 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpqFJzsx3wTi3t3X/eOizU6rdtNQoqg5uSjL89F+Ojjm2/sah3ouzx+3E461FDYaoJL58Qs9eRhL+ev0BY7khYXph8nIVDzNEjhLqjevX+YhpaW9Ll7V807CwAyvMNm08aup/NrrlI/jO+At348/ivJrfO7ClcPhq4+Id9RZfvbrKaitGOURD7q6Bd7xjUjELUN8wmYxu5zvx/2n/5woVdBUMXamTPxOY5y6DxTNJ+EYzrCr+bNb7459rWUvBHUQGI2fXDGmFpGiv6ShKRhRtwob1JHI8QC9OtxonrIUesa2dW6RFneUaM7tfRfffC704Uo7yuSswb7YK+p1A9QIt5 nicolas@tchoum'
  SSH_KEY_1 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz0pLXcQWS4gLUimUSLwDOvEmQF8l8EKoj0LjxOyM3y2dpLsn0aiqS0ecA0G/ROomaawop8EZGFetoJKJM468OZlx2aKoQemzvFIq0Mn1ZhcrlA1alAsDYqzZI8iHO4JIS3YbeLLkVGAlYA+bmA5enXN9mGhC9cgoMC79EZiLD9XvOw4iXDjqXaCzFZHU1shMWwaJfpyxBm+Mxs2vtZzwETDqeu9rohNMl60dODf6+JoXYiahP+B+P2iKlL7ORb1YsAH/4ZMsVgRckj8snb4uc3XgwLRNNw+oB78ApZGr0j3Zc32U9rpmulbHIroWO07OV4Xsplnu8lhGvfodA2gjb nicolas@tchoum'
  SSH_KEY_2 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5+JfM82k03J98GWL6ghJ4TYM8DbvDnVh1s1rUDNlM/1U5rwbgXHOR4xV3lulgYEYRtYeMoL3rt4ZpEyXWkOreOVsUlkW66SZJR5aGVTNJOLX7HruEDqj7RWlt0u0MH6DgBVAJimQrxYN50jYD4XnDUjb/qv55EhPvbJ3jcAb3zuyRXMKZYGNVzVFLUagbvVaOwR23csWSLDTsAEI9JzaxMKvCNRwk3jFepiCovXbw+g0iyvJdp0+AJpC57ZupyxHeX9J2oz7im2UaHHqLa2qUZL6c4PNV/D2p0Bts4Tcnn3OFPL90RF/ao0tjiUFxM3ti8pRHOqRcZHcOgIhKiaLX nicolas@tchoum'
  SSH_KEY_3 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/pSRh11xbadAh24fQlc0i0dneG0lI+DCkng+bVmumgRvfD0w79vcJ2U1qir2ChjpNvi2n96HUGIEGNV60/VG05JY70mEb//YVBmQ3w0QPO7toEWNms9SQlwR0PN6tarATumFik4MI+8M23P6W8O8OYwsnMmYwaiEU5hDopH88x74MQKjPiRSrhMkGiThMZhLVK6j8yfNPoj9yUxPBWc7zsMCC2uAOfR5Fg6hl2TKGxTi0vecTh1csDcO2agXx42RRiZeIQbv9j0IJjVL8KhXvbndVnJRjGGbxQFAedicw8OrPH7jz6NimmaTooqU9SwaPInK/x3omd297/zzcQm3p nicolas@tchoum'
  SSH_KEY_4 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCScLGus1vrZ9OyzOj3TtYa+IHUp5V+2hwcMW7pphGIAPRi5Pe6GwSbSV5GnanerOH9ucmEREaCIdGOzO2zVI35e3RD6wTeW28Ck7JN1r2LSgSvXGvxGyzu0H4Abf66Kajt+lN0/71tbFtoTaJTGSYE3W0rNU6OQBvHf1o4wIyBEFm3cu+e2OrmW/nVIqk8hCN2cU/0OutOWT+vaRLbIU3VQmHftqa4NVxdc4OG48vpZxlJwKexqAHj8Ok/sn3k4CIo8zR0vRaeGPqAmOpm84uEfRWoA71NNS4tIhENlikuD5SJIdyXE9d8CwGTth4jP9/BNT0y4C8cGYljjUWkx3v nicolas@tchoum'

  before(:all) do
    @user1 = create_user('git_user1')
    @user2 = create_user('git_user2')
  end

  # There is an isolation issue in tests.
  # Try to workaround it...
  def test_user
    'redmine_git_user1_12'
  end

  describe 'Valid SSH key build' do
    before(:each) do
      @ssh_key = build_ssh_key(title: 'test-key')
    end

    subject { @ssh_key }

    ## Relations
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:repository_deployment_credentials) }

    ## Validations
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:key_type) }

    it { is_expected.to validate_numericality_of(:key_type) }

    it { is_expected.to validate_inclusion_of(:key_type).in_array(%w[0 1]) }

    it { is_expected.to ensure_length_of(:title).is_at_most(60) }

    it { is_expected.not_to allow_value('toto@toto', 'ma_clé').for(:title) }

    it { is_expected.to respond_to(:identifier) }
    it { is_expected.to respond_to(:fingerprint) }
    it { is_expected.to respond_to(:owner) }
    it { is_expected.to respond_to(:location) }
    it { is_expected.to respond_to(:gitolite_path) }
    it { is_expected.to respond_to(:data_for_destruction) }

    ## Attributes content
    it 'can render as string' do
      expect(@ssh_key.to_s).to eq 'test-key'
    end

    it 'has a title' do
      expect(@ssh_key.title).to eq 'test-key'
    end

    it 'is a user key' do
      expect(@ssh_key.user_key?).to be true
    end

    it 'is not a deploy key' do
      expect(@ssh_key.deploy_key?).to be false
    end

    it 'must be deleted when unused' do
      expect(@ssh_key.delete_when_unused?).to be true
    end

    ## Test data integrity
    it 'should not truncate key' do
      expect(@ssh_key.key.length).to be == SSH_KEY_0.length
    end

    ## Test change validation
    describe 'when delete_when_unused is false' do
      it 'should not be deleted when unused' do
        @ssh_key.delete_when_unused = false
        expect(@ssh_key.delete_when_unused?).to be false
      end
    end

    describe 'when delete_when_unused is true' do
      it 'should be deleted when unused' do
        @ssh_key.delete_when_unused = true
        expect(@ssh_key.delete_when_unused?).to be true
      end
    end
  end

  describe 'Valid SSH key creation' do
    let(:ssh_key) { create_ssh_key(user_id: @user1.id, title: 'test-key') }

    subject { ssh_key }

    it 'has an identifier' do
      expect(ssh_key.identifier).to eq "#{test_user}@redmine_test_key"
    end

    it 'has a fingerprint' do
      expect(ssh_key.fingerprint).to eq "SHA256:VgXjWgUbURtD6go5HV7Eop2UqVjmIAI68shaB66yv+c"
    end

    it 'has a owner' do
      expect(ssh_key.owner).to eq test_user
    end

    it 'has a location' do
      expect(ssh_key.location).to eq 'redmine_test_key'
    end

    it 'has a gitolite_path' do
      expect(ssh_key.gitolite_path).to eq "keydir/redmine_git_hosting/#{test_user}/redmine_test_key/#{test_user}.pub"
    end

    it 'it has data hash for destruction' do
      valid_hash = { key: SSH_KEY_0, location: 'redmine_test_key', owner: test_user, title: "#{test_user}@redmine_test_key" }
      expect(ssh_key.data_for_destruction).to eq valid_hash
    end

    context 'when identifier is changed' do
      before { ssh_key.identifier = 'foo' }

      it { is_expected.not_to be_valid }
    end

    context 'when key is changed' do
      before { ssh_key.key = 'foo' }

      it { is_expected.not_to be_valid }
    end

    context 'when user_id is changed' do
      before { ssh_key.user_id = @user2.id }

      it { is_expected.not_to be_valid }
    end

    context 'when key_type is changed' do
      before { ssh_key.key_type = 1 }

      it { is_expected.not_to be_valid }
    end

    # Test reset_identifiers
    context 'when identifiers are reset' do
      before do
        @old_identifier = ssh_key.identifier
        @old_fingerprint = ssh_key.fingerprint

        ssh_key.reset_identifiers
      end

      it { is_expected.to be_valid }

      it 'should have the same identifier' do
        expect(ssh_key.identifier).to eq @old_identifier
      end

      it 'should have the same fingerprint' do
        expect(ssh_key.fingerprint).to eq @old_fingerprint
      end
    end
  end

  describe 'Valid SSH key format' do
    describe 'when ssh key format is valid' do
      ssh_keys = [
        'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/Ec2gummukPxlpPHZ7K96iBdG5n8v0PJEDvTVZRRFlS0QYa407gj9HuMrPjwEfVHqy+3KZmvKLWQBsSlf0Fn+eAPgnoqwVfZaJnfgkSxJiAzRraKQZX1m2wx2SVMfjw7/1j59zV60UhFiwEQ3Eqlg3xjQmjvrwDM+SoshrWB+TeqwO/K+QEP1ZbURYoCxc92GrLYWKixsAov/zr0loXqul9fydZcWwJE3H/BWC7PTtn4jfjG9+9F+SZ0OMwQvSGKhVlj3GBDtaDBnsuoHGh/CA2W240nwpQysG2BJ5DWXu6vKbjNn6uV91wXeKDEDpuWqv5Vi2XAxGTWKc5lF0IJ5 nicolas@tchoum',
        'ssh-dss AAAAB3NzaC1kc3MAAACBAKscxrmjRgXtb0ZUaaBUteBtF2cI0vStnni9KVQd94L8qqxvKLbDl5JTKjUvG2s7rD4sVRzBoTkuDGb7OZLf56wJyF3k+k8uNRJzvH/CZbkKM2hjuRVYVort1EwcH7JiEQr7bCLe7MRaltuo/M1vhapwy7fhKxAo9YoYVWiGoFTVAAAAFQDPywT8yFDahFvxtt/95Q9Emq8R7QAAAIBHYnvt3hT9NYy+nOuZG+cQTz0hnVzUIWuj0XF2iyx52s2eSmF0HxIsZ0D9g2A0L1Xr/vlkWBMq/zJZJgJw2Ifys8L47HzjhL8K0Skdm23Z6rQR9hlOEZ5Rcank98U6VRYPWpYk7OLdRDruwXb+Ms5YhIztxsGO3YfRBdSBrW4DMAAAAIAJmmwivw3XoFP6C97LB+tJAjWRYJHpiDwOWNDKu0dZewUzUAo40NuHNgKJS2nsxW0sphaeMtf70IbvDsFQG45I+G2dlt+s19t4YCbVcz7xrw7LceEz+f0UR2/Z+LIK2GPIIoyymOq/kIIxni3xgKDl4mvvt45TTsQzs0zhkmEy/g== nicolas@tchoum',
        'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLIcYw8NbJc28tDsC+8sf/o14hQmQfdC31OFP0eb5qFVRgEjMJ9mwolqWIW+AcbIAhX2GJVdTLZoUJj6T5PiUtM= nicolas@tchoum'
      ]

      ssh_keys.each do |valid_key|
        it 'should be valid' do
          expect(build_ssh_key(key: valid_key)).to be_valid
        end
      end
    end
  end


  context 'when SSH key already exist' do
    before { create_ssh_key(user_id: @user1.id, title: 'test-key2') }

    ## Test uniqueness validation
    context 'and title is already taken' do
      it { expect(build_ssh_key(user_id: @user1.id, title: 'test-key2', key: SSH_KEY_1)).not_to be_valid }
    end

    context 'and is already taken by someone' do
      it { expect(build_ssh_key(user_id: @user1.id, title: 'foo')).not_to be_valid }
    end

    context 'and is already taken by current user' do
      it 'should_not be_valid' do
        User.current = @user1
        expect(build_ssh_key(user_id: @user1.id, title: 'foo')).not_to be_valid
      end
    end

    context 'and is already taken by other user and current user is admin' do
      it 'should_not be_valid' do
        @user2.admin = true
        User.current = @user2
        expect(build_ssh_key(user_id: @user1.id, title: 'foo')).not_to be_valid
      end
    end

    context 'and is already taken by other user and current user is not admin' do
      it 'should_not be_valid' do
        User.current = @user2
        expect(build_ssh_key(user_id: @user1.id, title: 'foo')).not_to be_valid
      end
    end
  end

  context 'when Gitolite Admin ssh key is reused' do
    it 'should not be valid' do
      expect(build_ssh_key(user_id: @user1.id, title: 'foo', key: File.read(RedmineGitHosting::Config.gitolite_ssh_public_key))).not_to be_valid
    end
  end

  context 'when many keys are saved' do
    before do
      create_ssh_key(user: @user1, title: 'active1', key: SSH_KEY_1, key_type: 1)
      create_ssh_key(user: @user1, title: 'active2', key: SSH_KEY_2, key_type: 1)
      create_ssh_key(user: @user2, title: 'active3', key: SSH_KEY_3)
      create_ssh_key(user: @user2, title: 'active4', key: SSH_KEY_4)
    end

    it 'should have 6 keys' do
      expect(GitolitePublicKey.all.length).to be == 5
    end

    it 'should have 2 user keys' do
      expect(GitolitePublicKey.user_key.length).to be == 2
    end

    it 'should have 4 deploy keys' do
      expect(GitolitePublicKey.deploy_key.length).to be == 3
    end

    it 'user1 should have 2 keys' do
      expect(@user1.gitolite_public_keys.length).to be == 2
    end

    it 'user2 should have 2 keys' do
      expect(@user2.gitolite_public_keys.length).to be == 2
    end
  end
end
