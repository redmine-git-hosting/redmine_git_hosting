require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe RepositoryMirrors::Push do

  let(:mirror_url) { 'ssh://git@redmine.example.org/project1/project2/project3/project4.git' }


  def build_mirror_pusher(opts = {})
    mirror = build(:repository_mirror, opts)
    RepositoryMirrors::Push.new(mirror)
  end


  describe 'Push args' do
    ## Validate push args : forced mode
    context 'when push_mode forced with params' do
      it 'should have command' do
        mirror_pusher = build_mirror_pusher(url: mirror_url, push_mode: 1, explicit_refspec: 'devel')
        expect(mirror_pusher.command).to eq [mirror_url, 'devel', ['--force']]
      end
    end

    ## Validate push args : fast_forward mode
    context 'when push_mode fast_forward with params' do
      it 'should have command' do
        mirror_pusher = build_mirror_pusher(url: mirror_url, push_mode: 2, explicit_refspec: 'devel')
        expect(mirror_pusher.command).to eq [mirror_url, 'devel', []]
      end
    end

    ## Validate push args : mirror mode
    context 'when push_mode is mirror' do
      it 'should have command' do
        mirror_pusher = build_mirror_pusher(url: mirror_url, push_mode: 0)
        expect(mirror_pusher.command).to eq [mirror_url, nil, ['--mirror']]
      end
    end

    ## Validate push args : all tags mode
    context 'when push_mode is all tags' do
      it 'should have command' do
        mirror_pusher = build_mirror_pusher(url: mirror_url, push_mode: 1, include_all_tags: true)
        expect(mirror_pusher.command).to eq [mirror_url, nil, ['--force', '--tags']]
      end
    end

    ## Validate push args : all branches mode
    context 'when push_mode is all branches' do
      it 'should have command' do
        mirror_pusher = build_mirror_pusher(url: mirror_url, push_mode: 1, include_all_branches: true)
        expect(mirror_pusher.command).to eq [mirror_url, nil, ['--force', '--all']]
      end
    end
  end

end
