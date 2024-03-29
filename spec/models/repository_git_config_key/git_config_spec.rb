# frozen_string_literal: true

require File.expand_path "#{File.dirname __FILE__}/../../spec_helper"

describe RepositoryGitConfigKey::GitConfig do
  before :each do
    @git_config_key = build :repository_git_config_key
  end

  subject { @git_config_key }

  ## Validations
  it { should be_valid }
  it { should validate_presence_of(:key) }
  it { should validate_uniqueness_of(:key).case_insensitive.scoped_to(:type, :repository_id) }
  it { should allow_value('hookfoo.foo', 'hookfoo.foo.bar').for(:key) }
  it { should_not allow_value('hookfoo').for(:key) }

  context 'when key is updated' do
    before do
      @git_config_key.save
      @git_config_key.key = 'hookbar.foo'
      @git_config_key.save
    end

    it { should be_valid }
  end
end
