require 'spec_helper'

module Deface
  describe TemplateHelper do
    include_context "mock Rails.application"
    include Deface::TemplateHelper

    describe "load_template_source" do
      before do
        #stub view paths to be local spec/assets directory
        allow(ActionController::Base).to receive(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])
      end

      describe "with no overrides defined" do
        it "should return source for partial" do
          expect(load_template_source("shared/post", true)).to eq "<p>I'm from shared/post partial</p>\n<%= \"And I've got ERB\" %>\n"
        end

        it "should return converted source for partial containing haml" do
          expect(load_template_source("shared/hello", true)).to eq "<div class='<%= @some %>' id='message'><%= 'Hello, World!' %></div>\n"
        end

        it "should return converted source for partial containing slim" do
          expect(load_template_source("shared/hi", true)).to eq "<div class=\"some\" id=\"message\"><%= ::Temple::Utils.escape_html_safe((\"Hi, World!\")) %>\n</div>"
        end

        it "should return source for template" do
          expect(load_template_source("shared/person", false)).to eq "<p>I'm from shared/person template</p>\n<%= \"I've got ERB too\" %>\n"
        end

        it "should return converted source for template containing haml" do
          expect(load_template_source("shared/pirate", false).gsub(/\s/, '')).to eq "<divid='content'><divclass='left'><p><%=print_information%></p></div><divclass='right'id='<%=@right%>'><%=render:partial=>\"sidebar\"%></div></div>"
        end

        it "should return converted source for template containing slim" do
          result = "<divid=\"content\"><divclass=\"left\"><p><%=::Temple::Utils.escape_html_safe((print_information))%></p></div><divclass=\"right\"<%_slim_codeattributes1=@right;if_slim_codeattributes1;if_slim_codeattributes1==true%>id=\"\"<%else%>id=\"<%=::Temple::Utils.escape_html_safe((_slim_codeattributes1))%>\"<%end;end%>><%=::Temple::Utils.escape_html_safe((render:partial=>\"sidebar\"))%></div></div>"
          expect(load_template_source("shared/public", false).gsub(/\s/, '')).to eq result
        end

        it "should return source for namespaced template" do
          expect(load_template_source("admin/posts/index", false)).to eq "<h1>Manage Posts</h1>\n"
        end

        it "should raise exception for non-existing file" do
          expect { load_template_source("tester/post", true) }.to raise_error(ActionView::MissingTemplate)
        end

      end

      describe "with overrides defined" do
        include_context "mock Rails.application"

        before(:each) do
          Deface::Override.new(:virtual_path => "shared/_post", :name => "shared#post", :remove => "p")
          Deface::Override.new(:virtual_path => "shared/person", :name => "shared#person", :replace => "p", :text => "<h1>Argh!</h1>")
          Deface::Override.new(:virtual_path => "shared/_hello", :name => "shared#hello", :replace_contents => "div#message", :text => "<%= 'Goodbye World!' %>")
          Deface::Override.new(:virtual_path => "shared/pirate", :name => "shared#pirate", :replace => "p", :text => "<h1>Argh!</h1>")
          Deface::Override.new(:virtual_path => "admin/posts/index", :name => "admin#posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        end

        it "should return overridden source for partial including overrides" do
          expect(load_template_source("shared/post", true).strip).to eq "<%= \"And I've got ERB\" %>"
        end

        it "should return converted and overridden source for partial containing haml" do
          expect(load_template_source("shared/hello", true).strip).to eq "<div class=\"<%= @some %>\" id=\"message\"><%= 'Goodbye World!' %></div>"
        end

        it "should return converted and overridden source for partial containing slim" do
          expect(load_template_source("shared/hi", true)).to eq "<div class=\"some\" id=\"message\"><%= ::Temple::Utils.escape_html_safe((\"Hi, World!\")) %>\n</div>"
        end

        it "should return overridden source for partial excluding overrides" do
          expect(load_template_source("shared/post", true, false)).to eq "<p>I'm from shared/post partial</p>\n<%= \"And I've got ERB\" %>\n"
        end

        it "should return overridden source for template including overrides" do
          expect(load_template_source("shared/person", false).strip).to eq "<h1>Argh!</h1>\n<%= \"I've got ERB too\" %>"
        end

        it "should return converted and overridden source for template containing haml" do
          expect(load_template_source("shared/pirate", false).gsub(/\s/, '')).to eq "<divid=\"content\"><divclass=\"left\"><h1>Argh!</h1></div><divclass=\"right\"id=\"<%=@right%>\"><%=render:partial=>\"sidebar\"%></div></div>"
        end

        it "should return converted and overridden source for template containing slim" do
          result = "<divid=\"content\"><divclass=\"left\"><p><%=::Temple::Utils.escape_html_safe((print_information))%></p></div><divclass=\"right\"<%_slim_codeattributes1=@right;if_slim_codeattributes1;if_slim_codeattributes1==true%>id=\"\"<%else%>id=\"<%=::Temple::Utils.escape_html_safe((_slim_codeattributes1))%>\"<%end;end%>><%=::Temple::Utils.escape_html_safe((render:partial=>\"sidebar\"))%></div></div>"
          expect(load_template_source("shared/public", false).gsub(/\s/, '')).to eq result
        end

        it "should return source for namespaced template including overrides" do
          expect(load_template_source("admin/posts/index", false).strip).to eq "<h1>Argh!</h1>"
        end

      end

    end

    describe "element_source" do
      it "should return array of matches elements" do
        expect(element_source('<div><p class="pirate">Arrgh!</p><img src="/some/image.jpg"></div>', 'p.pirate').map(&:strip)).to eq ["<p class=\"pirate\">Arrgh!</p>"]
        expect(element_source('<div><p class="pirate">Arrgh!</p><p>No pirates here...</p></div>', 'p').map(&:strip)).to eq  ["<p class=\"pirate\">Arrgh!</p>", "<p>No pirates here...</p>"]
      end

      it "should return empty array for no matches" do
        expect(element_source('<div><p class="pirate">Arrgh!</p><img src="/some/image.jpg"></div>', 'span')).to eq []
      end
    end
  end
end
