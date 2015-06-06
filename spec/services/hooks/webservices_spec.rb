require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Hooks::Webservices do

  GLOBAL_PAYLOAD   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/global_payload.yml')))
  MASTER_PAYLOAD   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/master_payload.yml')))
  BRANCHES_PAYLOAD = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../../fixtures/branches_payload.yml')))


  describe "#needs_push" do
    before do
      @post_receive_url = build(:repository_post_receive_url)
    end

    context "when payload is empty" do
      before do
        @web_hook = Hooks::Webservices.new(@post_receive_url, [])
      end

      it "shoud return false" do
        expect(@web_hook.needs_push?).to be false
      end
    end

    context "when triggers are not used" do
      before do
        @web_hook = Hooks::Webservices.new(@post_receive_url, GLOBAL_PAYLOAD)
      end

      it "should return the global payload to push" do
        expect(@web_hook.needs_push?).to be true
        expect(@web_hook.payloads_to_send).to eq GLOBAL_PAYLOAD
      end
    end

    context "when triggers are empty" do
      before do
        @post_receive_url.use_triggers = true
        @web_hook = Hooks::Webservices.new(@post_receive_url, GLOBAL_PAYLOAD)
      end

      it "should return the global payload to push" do
        expect(@web_hook.needs_push?).to be false
        expect(@web_hook.payloads_to_send).to eq []
      end
    end

    context "when triggers is set to master" do
      before do
        @post_receive_url.use_triggers = true
        @post_receive_url.triggers = ['master']
        @web_hook = Hooks::Webservices.new(@post_receive_url, GLOBAL_PAYLOAD)
      end

      it "should return the master payload" do
        expect(@web_hook.needs_push?).to be true
        expect(@web_hook.payloads_to_send).to eq MASTER_PAYLOAD
      end
    end

    context "when triggers is set to master" do
      before do
        @post_receive_url.use_triggers = true
        @post_receive_url.triggers = ['master']
        @web_hook = Hooks::Webservices.new(@post_receive_url, BRANCHES_PAYLOAD)
      end

      it "should not be found in branches payload and return false" do
        expect(@web_hook.needs_push?).to be false
      end
    end
  end

end
