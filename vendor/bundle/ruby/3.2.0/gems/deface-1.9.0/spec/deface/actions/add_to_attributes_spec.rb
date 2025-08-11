require 'spec_helper'

module Deface
  module Actions
    describe AddToAttributes do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

      describe "with a single add_to_attributes override (containing only text) defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                        :attributes => {:class => 'pretty', :alt => 'something interesting'}) }
        let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

        it "should return modified source" do
          attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

          expect(attrs["class"].value).to eq("button pretty")
          expect(attrs["alt"].value).to eq("something interesting")
        end
      end

      describe "with a single add_to_attributes override (containing erb) defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                        :attributes => {:class => '<%= add_class %>'}) }
        let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

        it "should return modified source" do
          attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

          expect(attrs["class"].value).to eq("button <%= add_class %>")
          expect(attrs["src"].value).to eq("path/to/button.png")
        end
      end

      describe "with a single add_to_attributes override (containing erb) defined using pseudo attribute name" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                        :attributes => {'data-erb-class' => '<%= add_class %>'}) }
        let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

        it "should return modified source" do
          attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

          expect(attrs["class"].value).to eq("button <%= add_class %>")
          expect(attrs["src"].value).to eq("path/to/button.png")
        end
      end

      describe "with a single add_to_attributes override (containing erb) defined targetting an existing pseudo attribute" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                        :attributes => {:class => '<%= get_some_other_class %>'}) }
        let(:source) { "<img class=\"<%= get_class %>\" src=\"path/to/button.png\">" }

        it "should return modified source" do
          attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

          expect(attrs["class"].value).to eq("<%= get_class %> <%= get_some_other_class %>")
          expect(attrs["src"].value).to eq("path/to/button.png")
        end
      end
    end
  end
end
