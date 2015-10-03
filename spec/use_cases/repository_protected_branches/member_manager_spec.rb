require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe RepositoryProtectedBranches::MemberManager do

  def build_member_manager(opts = {})
    protected_branch = build(:repository_protected_branche)
    member_manager = RepositoryProtectedBranches::MemberManager.new(protected_branch)
  end


  let(:member_manager) { build_member_manager }

  subject { member_manager }

  describe '#current_user_ids' do
    it 'should return an array of user ids' do
      user = build(:user, id: 12)
      expect(member_manager.protected_branch).to receive(:users).and_return([user])
      expect(member_manager.current_user_ids).to eq [12]
    end
  end


  describe '#current_group_ids' do
    it 'should return an array of group ids' do
      group = build(:group, id: 12)
      expect(member_manager.protected_branch).to receive(:groups).and_return([group])
      expect(member_manager.current_group_ids).to eq [12]
    end
  end


  describe '#current_members' do
    it 'should return the current protected_branch members' do
      expect(member_manager.protected_branch).to receive(:protected_branches_members)
      member_manager.current_members
    end
  end


  describe '#users_by_group_id' do
    it 'should return the members of a protected_branch group' do
      group_member = create(:protected_branch_group_member)
      user_member  = create(:protected_branch_user_member, inherited_by: group_member.id)
      expect(member_manager).to receive(:current_members).and_return([user_member, group_member])
      expect(member_manager.users_by_group_id(1)).to eq [user_member.principal]
    end
  end


  describe '#add_users' do
    it 'should add users passed' do
      expect(member_manager).to receive(:current_user_ids).and_return([1])
      expect(member_manager).to receive(:create_member).with(['10'], [1], 'User', {})
      member_manager.add_users(['10'])
    end
  end


  describe '#add_groups' do
    it 'should add users passed' do
      user  = build(:user, id: 42)
      group = build(:group, id: 10)
      expect(member_manager).to receive(:current_group_ids).and_return([])
      expect(member_manager).to receive(:create_group_member).with(['10'], []).and_yield(group)
      expect(group).to receive(:users).and_return([user])
      expect(member_manager).to receive(:users_by_group_id).and_return([])
      expect(member_manager).to receive(:create_user_member).with([42], [], inherited_by: 10, destroy: false)
      member_manager.add_groups(['10'])
    end
  end


  describe '#create_user_member' do
    it 'should create a new user member' do
      expect(member_manager).to receive(:create_member).with([1], [], 'User', {})
      member_manager.create_user_member([1], [])
    end
  end


  describe '#create_group_member' do
    it 'should create a new group member' do
      expect(member_manager).to receive(:create_member).with([1], [], 'Group', {})
      member_manager.create_group_member([1], [])
    end
  end


  describe '#add_user_from_group' do
    it 'should add a user from a group' do
      user1 = build(:user, id: 20)
      user2 = build(:user, id: 22)
      expect(member_manager).to receive(:users_by_group_id).once.with(10).and_return([user2])
      expect(member_manager).to receive(:users_by_group_id).once.with(10).and_return([user2])
      expect(member_manager).to receive(:create_user_member).with([user2.id, user1.id], [user2.id], inherited_by: 10, destroy: false)
      member_manager.add_user_from_group(user1, 10)
    end
  end


  describe '#remove_user_from_group' do
    context 'when user exists' do
      it 'should remove a user from a group' do
        user = build(:user)
        expect(member_manager).to receive(:users_by_group_id).with(10).and_return([user])
        expect(member_manager.current_members).to receive(:find_by_protected_branch_id_and_principal_id_and_inherited_by)
        member_manager.remove_user_from_group(user, 10)
      end
    end

    context 'when user doesnt no exist' do
      it 'should return' do
        user = build(:user)
        expect(member_manager).to receive(:users_by_group_id).with(10).and_return([])
        expect(member_manager.current_members).to_not receive(:find_by_protected_branch_id_and_principal_id_and_inherited_by)
        member_manager.remove_user_from_group(user, 10)
      end
    end
  end


  describe '#create_member' do
    it 'should create member' do
      user = build(:user, id: 12)
      expect(User).to receive(:find_by_id).with(12).and_return(user)
      expect(member_manager.current_members).to receive(:create).with(principal_id: user.id, inherited_by: 10)
      expect(member_manager.current_members).to receive(:select).and_return([])
      member_manager.create_member([12], [], 'User', inherited_by: 10)
    end

    context 'when member is a user' do
      it 'should create member' do
        user = build(:user, id: 12)
        expect(User).to receive(:find_by_id).with(12).and_return(user)
        expect(member_manager.current_members).to receive(:create).with(principal_id: user.id, inherited_by: 10)
        member_manager.create_member([12], [], 'User', inherited_by: 10, destroy: false)
      end
    end

    context 'when member is a group' do
      it 'should create member' do
        group = build(:group, id: 12)
        expect(Group).to receive(:find_by_id).with(12).and_return(group)
        expect(member_manager.current_members).to receive(:create).with(principal_id: group.id, inherited_by: nil)
        member_manager.create_member([12], [], 'Group', destroy: false)
      end
    end
  end

end
