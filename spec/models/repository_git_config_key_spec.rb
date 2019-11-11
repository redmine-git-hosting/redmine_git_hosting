require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitConfigKey do

  let(:git_config_key) { build(:repository_git_config_key_base) }

  subject { git_config_key }

  ## Relations
  it { should belong_to(:repository) }

  ## Validations
  it { should validate_presence_of(:repository_id) }
  it { should validate_presence_of(:value) }
end
