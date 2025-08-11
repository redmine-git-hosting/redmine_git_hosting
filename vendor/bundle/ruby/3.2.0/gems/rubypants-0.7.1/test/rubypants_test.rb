require_relative 'helper'

require 'minitest/autorun'
require_relative '../lib/rubypants'

# Test EVERYTHING against SmartyPants.pl output!


class RubyPantsTest < Minitest::Test
  def assert_rp_equal(str, orig, options=[2], entities = {})
    assert_equal orig, RubyPants.new(str, options, entities).to_html
  end

  def refute_rp_equal(str, orig, options=[2], entities = {})
    refute_equal orig, RubyPants.new(str, options, entities).to_html
  end

  def assert_verbatim(str)
    assert_rp_equal str, str
  end

  def test_verbatim
    assert_verbatim "foo!"
    assert_verbatim "<div>This is HTML</div>"
    assert_verbatim "<div>This is HTML with <crap </div> tags>"
    assert_verbatim <<EOF
multiline

<b>html</b>

code

EOF
  end

  def test_quotes
    assert_rp_equal '"A first example"', '&#8220;A first example&#8221;'
    assert_rp_equal '"A first "nested" example"',
                    '&#8220;A first &#8220;nested&#8221; example&#8221;'

    assert_rp_equal '".', '&#8221;.'
    assert_rp_equal '"a', '&#8220;a'

    assert_rp_equal "'.", '&#8217;.'
    assert_rp_equal "'a", '&#8216;a'

    assert_rp_equal %{<p>He said, "'Quoted' words in a larger quote."</p>},
    "<p>He said, &#8220;&#8216;Quoted&#8217; words in a larger quote.&#8221;</p>"

    assert_rp_equal %{"I like the 70's"}, '&#8220;I like the 70&#8217;s&#8221;'
    assert_rp_equal %{"I like the '70s"}, '&#8220;I like the &#8217;70s&#8221;'
    assert_rp_equal %{"I like the '70!"}, '&#8220;I like the &#8216;70!&#8221;'

    assert_rp_equal 'pre"post', 'pre&#8221;post'
    assert_rp_equal 'pre "post', 'pre &#8220;post'
    assert_rp_equal 'pre&nbsp;"post', 'pre&nbsp;&#8220;post'
    assert_rp_equal 'pre--"post', 'pre&#8211;&#8220;post'
    assert_rp_equal 'pre--"!', 'pre&#8211;&#8221;!'

    assert_rp_equal "pre'post", 'pre&#8217;post'
    assert_rp_equal "pre 'post", 'pre &#8216;post'
    assert_rp_equal "pre&nbsp;'post", 'pre&nbsp;&#8216;post'
    assert_rp_equal "pre--'post", 'pre&#8211;&#8216;post'
    assert_rp_equal "pre--'!", 'pre&#8211;&#8217;!'

    assert_rp_equal "<b>'</b>", "<b>&#8216;</b>"
    assert_rp_equal "foo<b>'</b>", "foo<b>&#8217;</b>"

    assert_rp_equal '<b>"</b>', "<b>&#8220;</b>"
    assert_rp_equal 'foo<b>"</b>', "foo<b>&#8221;</b>"

    assert_rp_equal "foo\u00a0\"bar\"", "foo\u00a0&#8220;bar&#8221;"
    assert_rp_equal "foo\u00a0'bar'", "foo\u00a0&#8216;bar&#8217;"
  end

  def test_dashes
    assert_rp_equal "foo--bar", 'foo&#8212;bar', 1
    assert_rp_equal "foo---bar", 'foo---bar', 1
    assert_rp_equal "foo----bar", 'foo----bar', 1
    assert_rp_equal "--foo--bar--quux--",
                    '&#8212;foo&#8212;bar&#8212;quux&#8212;', 1

    assert_rp_equal "foo--bar", 'foo&#8288;&#8212;bar', [1, :prevent_breaks]
    assert_rp_equal "foo --bar", 'foo &#8212;bar', 1
    assert_rp_equal "foo --bar", 'foo&nbsp;&#8212;bar', [1, :prevent_breaks]
    assert_rp_equal "foo -- bar", 'foo&nbsp;&#8212; bar', [1, :prevent_breaks]
    assert_rp_equal "foo  --bar", 'foo&nbsp;&#8212;bar', [1, :prevent_breaks]

    assert_rp_equal "foo--bar", 'foo&#8211;bar', 2
    assert_rp_equal "foo---bar", 'foo&#8212;bar', 2
    assert_rp_equal "foo----bar", 'foo----bar', 2
    assert_rp_equal "--foo--bar--quux--",
                    '&#8211;foo&#8211;bar&#8211;quux&#8211;', 2

    assert_rp_equal "foo--bar", 'foo&#8288;&#8211;bar', [2, :prevent_breaks]
    assert_rp_equal "foo --bar", 'foo &#8211;bar', 2
    assert_rp_equal "foo --bar", 'foo&nbsp;&#8211;bar', [2, :prevent_breaks]
    assert_rp_equal "foo -- bar", 'foo&nbsp;&#8211; bar', [2, :prevent_breaks]
    assert_rp_equal "foo  --bar", 'foo&nbsp;&#8211;bar', [2, :prevent_breaks]

    assert_rp_equal "foo---bar", 'foo&#8288;&#8212;bar', [2, :prevent_breaks]
    assert_rp_equal "foo ---bar", 'foo &#8212;bar', 2
    assert_rp_equal "foo ---bar", 'foo&nbsp;&#8212;bar', [2, :prevent_breaks]
    assert_rp_equal "foo --- bar", 'foo&nbsp;&#8212; bar', [2, :prevent_breaks]
    assert_rp_equal "foo  ---bar", 'foo&nbsp;&#8212;bar', [2, :prevent_breaks]

    assert_rp_equal "foo--bar", 'foo&#8212;bar', 3
    assert_rp_equal "foo---bar", 'foo&#8211;bar', 3
    assert_rp_equal "foo----bar", 'foo----bar', 3
    assert_rp_equal "--foo--bar--quux--",
                    '&#8212;foo&#8212;bar&#8212;quux&#8212;', 3

    assert_rp_equal "foo--bar", 'foo&#8288;&#8212;bar', [3, :prevent_breaks]
    assert_rp_equal "foo --bar", 'foo &#8212;bar', 3
    assert_rp_equal "foo --bar", 'foo&nbsp;&#8212;bar', [3, :prevent_breaks]
    assert_rp_equal "foo -- bar", 'foo&nbsp;&#8212; bar', [3, :prevent_breaks]
    assert_rp_equal "foo  --bar", 'foo&nbsp;&#8212;bar', [3, :prevent_breaks]

    assert_rp_equal "foo---bar", 'foo&#8288;&#8211;bar', [3, :prevent_breaks]
    assert_rp_equal "foo ---bar", 'foo &#8211;bar', 3
    assert_rp_equal "foo ---bar", 'foo&nbsp;&#8211;bar', [3, :prevent_breaks]
    assert_rp_equal "foo --- bar", 'foo&nbsp;&#8211; bar', [3, :prevent_breaks]
    assert_rp_equal "foo  ---bar", 'foo&nbsp;&#8211;bar', [3, :prevent_breaks]
  end

  def test_html_comments
    assert_verbatim "<!-- comment -->"
    assert_verbatim "<!-- <p>foo bar</p> -->"
    assert_verbatim "<!-- <p>foo\nbar</p> -->"
    assert_rp_equal "--<!-- -- -->--", '&#8211;<!-- -- -->&#8211;'
  end

  def test_pre_tags
    assert_verbatim "<pre>--</pre>"
    assert_verbatim "<pre><code>--</code>--</pre>"
    assert_rp_equal "--<pre>--</pre>", '&#8211;<pre>--</pre>'
  end

  def test_ellipses
    assert_rp_equal "foo..bar", 'foo..bar', [:ellipses]
    assert_rp_equal "foo...bar", 'foo&#8230;bar', [:ellipses]
    assert_rp_equal "foo....bar", 'foo....bar', [:ellipses]
    # and with :prevent_breaks
    assert_rp_equal "foo..bar", 'foo..bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo...bar", 'foo&#8288;&#8230;bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo....bar", 'foo....bar', [:ellipses, :prevent_breaks]

    # dots and spaces
    assert_rp_equal "foo. . .bar", 'foo&#8230;bar', [:ellipses]
    assert_rp_equal "foo . . . bar", 'foo &#8230; bar', [:ellipses]
    assert_rp_equal "foo. . . .bar", 'foo. . . .bar', [:ellipses]
    assert_rp_equal "foo . . . . bar", 'foo . . . . bar', [:ellipses]
    # and with :prevent_breaks
    assert_rp_equal "foo. . .bar", 'foo&#8288;&#8230;bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo . . . bar", 'foo&nbsp;&#8230; bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo. . . .bar", 'foo. . . .bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo . . . . bar", 'foo . . . . bar', [:ellipses, :prevent_breaks]

    # dots and tab-spaces
    refute_rp_equal "foo.	.	.bar", 'foo&#8230;bar', [:ellipses]
    refute_rp_equal "foo	.	.	.	bar", 'foo	&#8230;	bar', [:ellipses]
    assert_rp_equal "foo.	.	.	.bar", 'foo.	.	.	.bar', [:ellipses]
    assert_rp_equal "foo	.	.	.	.	bar", 'foo	.	.	.	.	bar', [:ellipses]
    # and with :prevent_breaks
    refute_rp_equal "foo.	.	.bar", 'foo&#8288;&#8230;bar', [:ellipses, :prevent_breaks]
    refute_rp_equal "foo	.	.	.	bar", 'foo&nbsp;&#8230;	bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo.	.	.	.bar", 'foo.	.	.	.bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo	.	.	.	.	bar", 'foo	.	.	.	.	bar', [:ellipses, :prevent_breaks]

    # dots and line-breaks
    refute_rp_equal "foo.\n.\n.bar", 'foo&#8230;bar', [:ellipses]
    refute_rp_equal "foo\n.\n.\n.\nbar", "foo\n&#8230;\nbar", [:ellipses]
    assert_rp_equal "foo.\n.\n.\n.bar", "foo.\n.\n.\n.bar", [:ellipses]
    assert_rp_equal "foo\n.\n.\n.\n.\nbar", "foo\n.\n.\n.\n.\nbar", [:ellipses]
    # and with :prevent_breaks
    refute_rp_equal "foo.\n.\n.bar", "foo&#8288;&#8230;bar", [:ellipses, :prevent_breaks]
    refute_rp_equal "foo\n.\n.\n.\nbar", "foo&nbsp;&#8230;\nbar", [:ellipses, :prevent_breaks]
    assert_rp_equal "foo.\n.\n.\n.bar", "foo.\n.\n.\n.bar", [:ellipses, :prevent_breaks]
    assert_rp_equal "foo\n.\n.\n.\n.\nbar", "foo\n.\n.\n.\n.\nbar", [:ellipses, :prevent_breaks]

    # nasty ones
    assert_rp_equal "foo. . ..bar", 'foo. . ..bar', [:ellipses]
    assert_rp_equal "foo. . ...bar", 'foo. . &#8230;bar', [:ellipses]
    assert_rp_equal "foo. . ....bar", 'foo. . ....bar', [:ellipses]
    # and with :prevent_breaks
    assert_rp_equal "foo. . ..bar", 'foo. . ..bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo. . ...bar", 'foo. .&nbsp;&#8230;bar', [:ellipses, :prevent_breaks]
    assert_rp_equal "foo. . ....bar", 'foo. . ....bar', [:ellipses, :prevent_breaks]
  end

  def test_backticks
    assert_rp_equal "pre``post", 'pre&#8220;post'
    assert_rp_equal "pre ``post", 'pre &#8220;post'
    assert_rp_equal "pre&nbsp;``post", 'pre&nbsp;&#8220;post'
    assert_rp_equal "pre--``post", 'pre&#8211;&#8220;post'
    assert_rp_equal "pre--``!", 'pre&#8211;&#8220;!'

    assert_rp_equal "pre''post", 'pre&#8221;post'
    assert_rp_equal "pre ''post", 'pre &#8221;post'
    assert_rp_equal "pre&nbsp;''post", 'pre&nbsp;&#8221;post'
    assert_rp_equal "pre--''post", 'pre&#8211;&#8221;post'
    assert_rp_equal "pre--''!", 'pre&#8211;&#8221;!'
  end

  def test_single_backticks
    o = [:oldschool, :allbackticks]

    assert_rp_equal "`foo'", "&#8216;foo&#8217;", o

    assert_rp_equal "pre`post", 'pre&#8216;post', o
    assert_rp_equal "pre `post", 'pre &#8216;post', o
    assert_rp_equal "pre&nbsp;`post", 'pre&nbsp;&#8216;post', o
    assert_rp_equal "pre--`post", 'pre&#8211;&#8216;post', o
    assert_rp_equal "pre--`!", 'pre&#8211;&#8216;!', o

    assert_rp_equal "pre'post", 'pre&#8217;post', o
    assert_rp_equal "pre 'post", 'pre &#8217;post', o
    assert_rp_equal "pre&nbsp;'post", 'pre&nbsp;&#8217;post', o
    assert_rp_equal "pre--'post", 'pre&#8211;&#8217;post', o
    assert_rp_equal "pre--'!", 'pre&#8211;&#8217;!', o
  end

  def test_stupefy
    o = [:stupefy]

    assert_rp_equal "<p>He said, &#8220;&#8216;Quoted&#8217; words " +
                    "in a larger quote.&#8221;</p>",
                    %{<p>He said, "'Quoted' words in a larger quote."</p>}, o

    assert_rp_equal "&#8211; &#8212; &#8216;&#8217; &#8220;&#8221; &#8230;",
                    %{- -- '' "" ...}, o

    assert_rp_equal %{- -- '' "" ...}, %{- -- '' "" ...}, o
  end

  def test_process_escapes
    assert_rp_equal %q{foo\bar}, "foo\\bar"
    assert_rp_equal %q{foo\\\bar}, "foo&#92;bar"
    assert_rp_equal %q{foo\\\\\bar}, "foo&#92;\\bar"
    assert_rp_equal %q{foo\...bar}, "foo&#46;..bar"
    assert_rp_equal %q{foo\.\.\.bar}, "foo&#46;&#46;&#46;bar"

    assert_rp_equal %q{foo\'bar}, "foo&#39;bar"
    assert_rp_equal %q{foo\"bar}, "foo&#34;bar"
    assert_rp_equal %q{foo\-bar}, "foo&#45;bar"
    assert_rp_equal %q{foo\`bar}, "foo&#96;bar"

    assert_rp_equal %q{foo\#bar}, "foo\\#bar"
    assert_rp_equal %q{foo\*bar}, "foo\\*bar"
    assert_rp_equal %q{foo\&bar}, "foo\\&bar"
  end

  def test_modified_entities
    entities = {
      :single_left_quote  => 'SHAZAM',
      :single_right_quote => 'POWZAP'
    }
    assert_rp_equal "Testing 'FOO!'", "Testing SHAZAMFOO!POWZAP", [2], entities
  end

  def test_named_entities
    assert_rp_equal "Testing 'FOO!'", "Testing &lsquo;FOO!&rsquo;", [2, :named_entities]
  end

  def test_character_entities
    assert_rp_equal "Testing 'FOO!'", "Testing ‘FOO!’", [2, :character_entities]
    assert_rp_equal "foo---bar", "foo&#8288;—bar", [2, :character_entities, :prevent_breaks]
    assert_rp_equal "foo ---bar", "foo&nbsp;—bar", [2, :character_entities, :prevent_breaks]
    assert_rp_equal "foo ---bar", "foo\u00A0—bar", [2, :character_entities, :character_spaces, :prevent_breaks]
  end
end
