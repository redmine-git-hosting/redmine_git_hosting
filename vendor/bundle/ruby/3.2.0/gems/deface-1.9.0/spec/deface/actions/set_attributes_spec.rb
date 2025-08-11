require 'spec_helper'

module Deface
  module Actions
    describe SetAttributes do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single set_attributes override (containing only text) defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                        :attributes => {:class => 'pretty', :alt => 'something interesting'}) }
        let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

        it "should return modified source" do
          attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

          expect(attrs["class"].value).to eq("pretty")
          expect(attrs["alt"].value).to eq("something interesting")
          expect(attrs["src"].value).to eq("path/to/button.png")
        end
      end

      describe "with a single set_attributes override (containing erb) defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                        :attributes => {:class => 'pretty', 'data-erb-alt' => '<%= something_interesting %>'}) }
        let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

        it "should return modified source" do
          attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

          expect(attrs["class"].value).to eq("pretty")
          expect(attrs["alt"].value).to eq("<%= something_interesting %>")
          expect(attrs["src"].value).to eq("path/to/button.png")
        end
      end

      describe "with a single set_attributes override (containing erb) defined targetting an existing pseudo attribute" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                        :attributes => {:class => '<%= get_some_other_class %>', :alt => 'something interesting'}) }
        let(:source) { "<img class=\"<%= get_class %>\" src=\"path/to/button.png\">" }

        it "should return modified source" do
          attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

          expect(attrs["class"].value).to eq("<%= get_some_other_class %>")
          expect(attrs["alt"].value).to eq("something interesting")
          expect(attrs["src"].value).to eq("path/to/button.png")
        end
      end

      describe "with a single set_attributes override (containing a pseudo attribute with erb) defined targetting an existing pseudo attribute" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                        :attributes => {'class' => '<%= hello_world %>'}) }
        let(:source) { "<div><img class=\"<%= hello_moon %>\" src=\"path/to/button.png\"></div>" }

        it "should return modified source" do
          tag = Nokogiri::HTML::DocumentFragment.parse(Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", ""))
          tag = tag.css('img').first
          expect(tag.attributes['src'].value).to eq "path/to/button.png"
          expect(tag.attributes['class'].value).to eq "<%= hello_world %>"
        end
      end
    end
  end
end
