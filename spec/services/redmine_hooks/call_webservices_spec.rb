require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe RedmineHooks::CallWebservices do

  let(:global_payload) { load_yaml_fixture('global_payload.yml') }
  let(:master_payload) { load_yaml_fixture('master_payload.yml') }
  let(:branches_payload) { load_yaml_fixture('branches_payload.yml') }


  def build_web_hook(payload, opts = {})
    post_receive_url = build(:repository_post_receive_url, opts)
    RedmineHooks::CallWebservices.new(post_receive_url, payload)
  end


  describe '#needs_push' do
    context 'when payload is empty' do
      it 'shoud return false' do
        web_hook = build_web_hook([])
        expect(web_hook.needs_push?).to be false
      end
    end

    context 'when triggers are not used' do
      it 'should return the global payload to push' do
        web_hook = build_web_hook(global_payload)
        expect(web_hook.needs_push?).to be true
        expect(web_hook.payloads_to_send).to eq global_payload
      end
    end

    context 'when triggers are empty' do
      it 'should return the global payload to push' do
        web_hook = build_web_hook(global_payload, use_triggers: true)
        expect(web_hook.needs_push?).to be false
        expect(web_hook.payloads_to_send).to eq []
      end
    end

    context 'when triggers is set to master' do
      it 'should return the master payload' do
        web_hook = build_web_hook(global_payload, use_triggers: true, triggers: ['master'])
        expect(web_hook.needs_push?).to be true
        expect(web_hook.payloads_to_send).to eq master_payload
      end
    end

    context 'when triggers is set to master' do
      it 'should not be found in branches payload and return false' do
        web_hook = build_web_hook(branches_payload, use_triggers: true, triggers: ['master'])
        expect(web_hook.needs_push?).to be false
      end
    end
  end

end
