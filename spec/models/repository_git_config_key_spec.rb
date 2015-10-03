require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitConfigKey do

  let(:git_config_key) { build(:repository_git_config_key_base) }

  subject { git_config_key }

  ## Attributes
  it { should allow_mass_assignment_of(:type) }
  it { should allow_mass_assignment_of(:key) }
  it { should allow_mass_assignment_of(:value) }

  ## Relations
  it { should belong_to(:repository) }

  ## Validations
  it { should validate_presence_of(:repository_id) }
  it { should validate_presence_of(:value) }
end
