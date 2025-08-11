require 'spec_helper'

module Deface
  module Actions
    describe Remove do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single remove override defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>") }
        let(:source) { "<p>test</p><%= raw(text) %>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to eq("<%= raw(text) %>")
        end

      end

      describe "with a single remove override with closing_selector defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "h1", :closing_selector => "h2") }
        let(:source) { "<h2>I should be safe</h2><span>Before!</span><h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2><span>After!</span>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to eq("<h2>I should be safe</h2><span>Before!</span><span>After!</span>")
        end
      end

    end
  end
end
