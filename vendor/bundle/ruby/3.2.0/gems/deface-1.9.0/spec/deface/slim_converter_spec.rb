require 'spec_helper'

module Deface
  describe SlimConverter do
    include_context "mock Rails.application"

    def slim_to_erb(src)
      conv = Deface::SlimConverter.new(src)
      conv.result.gsub("\n", "")
    end

    describe "convert slim to erb" do
      it "should hanlde simple tags" do
        expect(slim_to_erb('div class="some" id="message"= "Hi, World!"')).to eq("<div class=\"some\" id=\"message\"><%= ::Temple::Utils.escape_html_safe((\"Hi, World!\")) %></div>")
      end

      it "should handle complex tags" do
        expect(slim_to_erb(%q{nav#top-nav-bar
  ul#nav-bar.inline data-hook=''
    - if true
      .nav-links.high_res
        li.dropdown
          .welcome Welcome #{Spree::User.first.email} &#9662;
          ul.dropdown
            li = link_to 'Account', account_path
            li = link_to 'Log out', logout_path
})).to eq("<nav id=\"top-nav-bar\"><ul class=\"inline\" data-hook=\"\" id=\"nav-bar\"><% if true %><div class=\"nav-links high_res\"><li class=\"dropdown\"><div class=\"welcome\">Welcome <%= ::Temple::Utils.escape_html_safe((Spree::User.first.email)) %> &#9662;</div><ul class=\"dropdown\"><li><%= ::Temple::Utils.escape_html_safe((link_to 'Account', account_path)) %></li><li><%= ::Temple::Utils.escape_html_safe((link_to 'Log out', logout_path)) %></li></ul></li></div><% end %></ul></nav>")
      end

      it "should handle Rails capturing" do
        expect(slim_to_erb(%q{#wishlist-form
	= form_for Spree::WishedProduct.new do |f|
		= f.submit 'Save'
})).to eq("<div id=\"wishlist-form\"><% _slim_controls1 = form_for Spree::WishedProduct.new do |f| %><%= ::Temple::Utils.escape_html_safe((f.submit 'Save')) %><% end %><%= ::Temple::Utils.escape_html_safe((_slim_controls1)) %></div>")
      end
    end

  end
end
