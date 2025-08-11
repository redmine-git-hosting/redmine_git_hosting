require 'spec_helper'

module Deface
  module Actions
    describe ReplaceContents do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single insert_after override defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "img.button", :text => "<% help %>") }
        let(:source) { "<div><img class=\"button\" src=\"path/to/button.png\"></div>" }

        it "should return modified source" do
          expect(Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "")).to eq("<div><img class=\"button\" src=\"path/to/button.png\"><% help %></div>")
        end
      end
    end
  end
end
