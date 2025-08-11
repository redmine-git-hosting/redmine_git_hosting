require 'spec_helper'

module Deface
  module Actions
    describe InsertTop do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single insert_top override defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_top => "ul", :text => "<li>me first</li>") }
        let(:source) { "<ul><li>first</li><li>second</li><li>third</li></ul>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "")).to eq("<ul><li>me first</li><li>first</li><li>second</li><li>third</li></ul>")
        end
      end

      describe "with a single insert_top override defined when targetted elemenet has no children" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_top => "ul", :text => "<li>first</li><li>second</li><li>third</li>") }
        let(:source) { "<ul></ul>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "")).to eq("<ul><li>first</li><li>second</li><li>third</li></ul>")
        end
      end
    end
  end
end
