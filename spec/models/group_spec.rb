require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Group do

  let(:group) { build(:group) }

  subject { group }

  it { should have_many(:protected_branches_members).dependent(:destroy) }
  it { should have_many(:protected_branches).through(:protected_branches_members) }
end
