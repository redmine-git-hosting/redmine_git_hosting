require File.expand_path('../spec_helper', __dir__)

describe Group do
  subject { group }

  let(:group) { build(:group) }

  it { is_expected.to have_many(:protected_branches_members).dependent(:destroy) }
  it { is_expected.to have_many(:protected_branches).through(:protected_branches_members) }
end
