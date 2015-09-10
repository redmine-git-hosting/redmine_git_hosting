require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe RedmineHooks::CallWebservices do

  GLOBAL_PAYLOAD   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/global_payload.yml')))
  MASTER_PAYLOAD   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/master_payload.yml')))
  BRANCHES_PAYLOAD = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/branches_payload.yml')))


  describe '#needs_push' do
    let(:post_receive_url){ build(:repository_post_receive_url) }

    context 'when payload is empty' do
      it 'shoud return false' do
        web_hook = RedmineHooks::CallWebservices.new(post_receive_url, [])
        expect(web_hook.needs_push?).to be false
      end
    end

    context 'when triggers are not used' do
      it 'should return the global payload to push' do
        web_hook = RedmineHooks::CallWebservices.new(post_receive_url, GLOBAL_PAYLOAD)
        expect(web_hook.needs_push?).to be true
        expect(web_hook.payloads_to_send).to eq GLOBAL_PAYLOAD
      end
    end

    context 'when triggers are empty' do
      it 'should return the global payload to push' do
        post_receive_url.use_triggers = true
        web_hook = RedmineHooks::CallWebservices.new(post_receive_url, GLOBAL_PAYLOAD)
        expect(web_hook.needs_push?).to be false
        expect(web_hook.payloads_to_send).to eq []
      end
    end

    context 'when triggers is set to master' do
      it 'should return the master payload' do
        post_receive_url.use_triggers = true
        post_receive_url.triggers = ['master']
        web_hook = RedmineHooks::CallWebservices.new(post_receive_url, GLOBAL_PAYLOAD)
        expect(web_hook.needs_push?).to be true
        expect(web_hook.payloads_to_send).to eq MASTER_PAYLOAD
      end
    end

    context 'when triggers is set to master' do
      it 'should not be found in branches payload and return false' do
        post_receive_url.use_triggers = true
        post_receive_url.triggers = ['master']
        web_hook = RedmineHooks::CallWebservices.new(post_receive_url, BRANCHES_PAYLOAD)
        expect(web_hook.needs_push?).to be false
      end
    end
  end

end
