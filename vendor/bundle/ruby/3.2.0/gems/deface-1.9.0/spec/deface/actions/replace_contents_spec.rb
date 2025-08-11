require 'spec_helper'

module Deface
  module Actions
    describe ReplaceContents do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single replace_contents override defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace_contents => "p", :text => "<h1>Argh!</h1>") }
        let(:source) { "<p><span>Hello</span>I am not a <em>pirate</em></p>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to eq("<p><h1>Argh!</h1></p>")
        end
      end

      describe "with a single replace_contents override with closing_selector defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace_contents => "h1", :closing_selector => "h2", :text => "<span>Argh!</span>") }
        let(:source) { "<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to eq("<h1>start</h1><span>Argh!</span><h2>end</h2>")
        end
      end
    end
  end
end

