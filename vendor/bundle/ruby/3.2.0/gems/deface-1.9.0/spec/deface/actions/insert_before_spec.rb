require 'spec_helper'

module Deface
  module Actions
    describe InsertBefore do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single insert_before override defined" do
        before  { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "ul li:last", :text => "<%= help %>") }
        let(:source) { "<ul><li>first</li><li>second</li><li>third</li></ul>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "")).to eq("<ul><li>first</li><li>second</li><li>third</li><%= help %></ul>")
        end
      end
    end
  end
end
