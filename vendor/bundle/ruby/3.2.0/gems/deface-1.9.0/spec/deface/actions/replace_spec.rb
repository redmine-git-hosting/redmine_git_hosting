require 'spec_helper'

module Deface
  module Actions
    describe Replace do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single replace override defined" do
        before { @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "p", :text => "<h1>Argh!</h1>") }
        let(:source) { "<p>test</p>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to  eq("<h1>Argh!</h1>")
          expect(@override.failure).to be_falsy
        end
      end

      describe "with a single replace override with closing_selector defined" do
        before { @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "h2", :text => "<span>Argh!</span>") }
        let(:source) { "<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to eq("<span>Argh!</span>")
          expect(@override.failure).to be_falsy
        end
      end

      describe "with a single replace override with bad closing_selector defined" do
        before { @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "h3", :text => "<span>Argh!</span>") }
        let(:source) { "<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>" }

        it "should log error and return unmodified source" do
          expect(Rails.logger).to receive(:info).with(/failed to match with end selector/)
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to eq(source)
          expect(@override.failure).to be_truthy
        end
      end

      describe "with a single replace override with bad selector defined" do
        before { @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h3", :closing_selector => "h2", :text => "<span>Argh!</span>") }
        let(:source) { "<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>" }

        it "should log error and return unmodified source" do
          expect(Rails.logger).to receive(:info).with(/failed to match with starting selector/)
          expect(Dummy.apply(source, {:virtual_path => "posts/index"})).to eq(source)
          expect(@override.failure).to be_truthy
        end
      end
    end
  end
end
