require 'creole'

class Bacon::Context
  def tc(html, creole, options = {})
    Creole.creolize(creole, options).should.equal html
  end

  def tce(html, creole)
    tc(html, creole, :extensions => true)
  end
end

describe Creole::Parser do
  it 'should parse bold' do
    # Creole1.0: Bold can be used inside paragraphs
    tc "<p>This <strong>is</strong> bold</p>", "This **is** bold"
    tc "<p>This <strong>is</strong> bold and <strong>bold</strong>ish</p>", "This **is** bold and **bold**ish"

    # Creole1.0: Bold can be used inside list items
    tc "<ul><li>This is <strong>bold</strong></li></ul>", "* This is **bold**"

    # Creole1.0: Bold can be used inside table cells
    tc("<table><tr><td>This is <strong>bold</strong></td></tr></table>",
       "|This is **bold**|")

    # Creole1.0: Links can appear inside bold text:
    tc("<p>A bold link: <strong><a href=\"http://wikicreole.org/\">http://wikicreole.org/</a> nice!</strong></p>",
       "A bold link: **http://wikicreole.org/ nice!**")

    # Creole1.0: Bold will end at the end of paragraph
    tc "<p>This <strong>is bold</strong></p>", "This **is bold"

    # Creole1.0: Bold will end at the end of list items
    tc("<ul><li>Item <strong>bold</strong></li><li>Item normal</li></ul>",
       "* Item **bold\n* Item normal")

    # Creole1.0: Bold will end at the end of table cells
    tc("<table><tr><td>Item <strong>bold</strong></td><td>Another <strong>bold</strong></td></tr></table>",
       "|Item **bold|Another **bold")

    # Creole1.0: Bold should not cross paragraphs
    tc("<p>This <strong>is</strong></p><p>bold<strong> maybe</strong></p>",
       "This **is\n\nbold** maybe")

    # Creole1.0-Implied: Bold should be able to cross lines
    tc "<p>This <strong>is bold</strong></p>", "This **is\nbold**"
  end

  it 'should parse italic' do
    # Creole1.0: Italic can be used inside paragraphs
    tc("<p>This <em>is</em> italic</p>",
       "This //is// italic")
    tc("<p>This <em>is</em> italic and <em>italic</em>ish</p>",
       "This //is// italic and //italic//ish")

    # Creole1.0: Italic can be used inside list items
    tc "<ul><li>This is <em>italic</em></li></ul>", "* This is //italic//"

    # Creole1.0: Italic can be used inside table cells
    tc("<table><tr><td>This is <em>italic</em></td></tr></table>",
       "|This is //italic//|")

    # Creole1.0: Links can appear inside italic text:
    tc("<p>A italic link: <em><a href=\"http://wikicreole.org/\">http://wikicreole.org/</a> nice!</em></p>",
       "A italic link: //http://wikicreole.org/ nice!//")

    # Creole1.0: Italic will end at the end of paragraph
    tc "<p>This <em>is italic</em></p>", "This //is italic"

    # Creole1.0: Italic will end at the end of list items
    tc("<ul><li>Item <em>italic</em></li><li>Item normal</li></ul>",
       "* Item //italic\n* Item normal")

    # Creole1.0: Italic will end at the end of table cells
    tc("<table><tr><td>Item <em>italic</em></td><td>Another <em>italic</em></td></tr></table>",
       "|Item //italic|Another //italic")

    # Creole1.0: Italic should not cross paragraphs
    tc("<p>This <em>is</em></p><p>italic<em> maybe</em></p>",
       "This //is\n\nitalic// maybe")

    # Creole1.0-Implied: Italic should be able to cross lines
    tc "<p>This <em>is italic</em></p>", "This //is\nitalic//"
  end

  it 'should parse bold italics' do
    # Creole1.0: By example
    tc "<p><strong><em>bold italics</em></strong></p>", "**//bold italics//**"

    # Creole1.0: By example
    tc "<p><em><strong>bold italics</strong></em></p>", "//**bold italics**//"

    # Creole1.0: By example
    tc "<p><em>This is <strong>also</strong> good.</em></p>", "//This is **also** good.//"
  end

  it 'should parse headings' do
    # Creole1.0: Only three differed sized levels of heading are required.
    tc "<h1>Heading 1</h1>", "= Heading 1 ="
    tc "<h2>Heading 2</h2>", "== Heading 2 =="
    tc "<h3>Heading 3</h3>", "=== Heading 3 ==="
    # WARNING: Optional feature, not specified in creole 1.0
    tc "<h4>Heading 4</h4>", "==== Heading 4 ===="
    tc "<h5>Heading 5</h5>", "===== Heading 5 ====="
    tc "<h6>Heading 6</h6>", "====== Heading 6 ======"

    # Creole1.0: Closing (right-side) equal signs are optional
    tc "<h1>Heading 1</h1>", "=Heading 1"
    tc "<h2>Heading 2</h2>", "== Heading 2"
    tc "<h3>Heading 3</h3>", " === Heading 3"

    # Creole1.0: Closing (right-side) equal signs don't need to be balanced and don't impact the kind of heading generated
    tc "<h1>Heading 1</h1>", "=Heading 1 ==="
    tc "<h2>Heading 2</h2>", "== Heading 2 ="
    tc "<h3>Heading 3</h3>", " === Heading 3 ==========="

    # Creole1.0: Whitespace is allowed before the left-side equal signs.
    tc "<h1>Heading 1</h1>", " \t= Heading 1 ="
    tc "<h2>Heading 2</h2>", " \t== Heading 2 =="

    # Creole1.0: Only white-space characters are permitted after the closing equal signs.
    tc "<h1>Heading 1</h1>", " = Heading 1 =   "
    tc "<h2>Heading 2</h2>", " == Heading 2 ==  \t  "

    # WARNING: !!Creole1.0 doesn't specify if text after closing equal signs
    # !!becomes part of the heading or invalidates the entire heading.
    # tc "<p> == Heading 2 == foo</p>", " == Heading 2 == foo"
    tc "<h2>Heading 2 == foo</h2>", " == Heading 2 == foo"

    # Creole1.0-Implied: Line must start with equal sign
    tc "<p>foo = Heading 1 =</p>", "foo = Heading 1 ="
  end

  it 'should parse links' do
    # Creole1.0: Links
    tc "<p><a href=\"link\">link</a></p>", "[[link]]"

    # Creole1.0: Links can appear in paragraphs (i.e. inline item)
    tc "<p>Hello, <a href=\"world\">world</a></p>", "Hello, [[world]]"

    # Creole1.0: Named links
    tc "<p><a href=\"MyBigPage\">Go to my page</a></p>", "[[MyBigPage|Go to my page]]"

    # Creole1.0: URLs
    tc "<p><a href=\"http://www.wikicreole.org/\">http://www.wikicreole.org/</a></p>", "[[http://www.wikicreole.org/]]"

    # Creole1.0: Single punctuation characters at the end of URLs
    # should not be considered a part of the URL.
    [',','.','?','!',':',';','\'','"'].each do |punct|
      esc_punct = CGI::escapeHTML(punct)
      tc "<p><a href=\"http://www.wikicreole.org/\">http://www.wikicreole.org/</a>#{esc_punct}</p>", "http://www.wikicreole.org/#{punct}"
    end
    # Creole1.0: Nameds URLs (by example)
    tc("<p><a href=\"http://www.wikicreole.org/\">Visit the WikiCreole website</a></p>",
       "[[http://www.wikicreole.org/|Visit the WikiCreole website]]")

    # WRNING: Parsing markup within a link is optional
    tc "<p><a href=\"Weird+Stuff\"><strong>Weird</strong> <em>Stuff</em></a></p>", "[[Weird Stuff|**Weird** //Stuff//]]"
    tc("<p><a href=\"http://example.org/\"><img src=\"image.jpg\"/></a></p>", "[[http://example.org/|{{image.jpg}}]]")

    # Inside bold
    tc "<p><strong><a href=\"link\">link</a></strong></p>", "**[[link]]**"

    # Whitespace inside [[ ]] should be ignored
    tc("<p><a href=\"link\">link</a></p>", "[[ link ]]")
    tc("<p><a href=\"link+me\">link me</a></p>", "[[ link me ]]")
    tc("<p><a href=\"http://dot.com/\">dot.com</a></p>", "[[  http://dot.com/ \t| \t dot.com ]]")
    tc("<p><a href=\"http://dot.com/\">dot.com</a></p>", "[[  http://dot.com/  |  dot.com ]]")
  end

  it 'should parse freestanding urls' do
    # Creole1.0: Free-standing URL's should be turned into links
    tc "<p><a href=\"http://www.wikicreole.org/\">http://www.wikicreole.org/</a></p>", "http://www.wikicreole.org/"

    # URL ending in .
    tc "<p>Text <a href=\"http://wikicreole.org\">http://wikicreole.org</a>. other text</p>", "Text http://wikicreole.org. other text"

    # URL ending in ),
    tc "<p>Text (<a href=\"http://wikicreole.org\">http://wikicreole.org</a>), other text</p>", "Text (http://wikicreole.org), other text"

    # URL ending in ).
    tc "<p>Text (<a href=\"http://wikicreole.org\">http://wikicreole.org</a>). other text</p>", "Text (http://wikicreole.org). other text"

    # URL ending in ).
    tc "<p>Text (<a href=\"http://wikicreole.org\">http://wikicreole.org</a>).</p>", "Text (http://wikicreole.org)."

    # URL ending in )
    tc "<p>Text (<a href=\"http://wikicreole.org\">http://wikicreole.org</a>)</p>", "Text (http://wikicreole.org)"
  end

  it 'should parse paragraphs' do
    # Creole1.0: One or more blank lines end paragraphs.
    tc "<p>This is my text.</p><p>This is more text.</p>", "This is\nmy text.\n\nThis is\nmore text."
    tc "<p>This is my text.</p><p>This is more text.</p>", "This is\nmy text.\n\n\nThis is\nmore text."
    tc "<p>This is my text.</p><p>This is more text.</p>", "This is\nmy text.\n\n\n\nThis is\nmore text."

    # Creole1.0: A list end paragraphs too.
    tc "<p>Hello</p><ul><li>Item</li></ul>", "Hello\n* Item\n"

    # Creole1.0: A table end paragraphs too.
    tc "<p>Hello</p><table><tr><td>Cell</td></tr></table>", "Hello\n|Cell|"

    # Creole1.0: A nowiki end paragraphs too.
    tc "<p>Hello</p><pre>nowiki</pre>", "Hello\n{{{\nnowiki\n}}}\n"

    # WARNING: A heading ends a paragraph (not specced)
    tc "<p>Hello</p><h1>Heading</h1>", "Hello\n= Heading =\n"
  end

  it 'should parse linebreaks' do
    # Creole1.0: \\ (wiki-style) for line breaks.
    tc "<p>This is the first line,<br/>and this is the second.</p>", "This is the first line,\\\\and this is the second."
  end

  it 'should parse unordered_lists' do
    # Creole1.0: List items begin with a * at the beginning of a line.
    # Creole1.0: An item ends at the next *
    tc "<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>", "* Item 1\n *Item 2\n *\t\tItem 3\n"

    # Creole1.0: Whitespace is optional before and after the *.
    tc("<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>",
       "   *    Item 1\n*Item 2\n \t*\t\tItem 3\n")

    # Creole1.0: A space is required if if the list element starts with bold text.
    tc("<ul><li><ul><li><ul><li>Item 1</li></ul></li></ul></li></ul>", "***Item 1")
    tc("<ul><li><strong>Item 1</strong></li></ul>", "* **Item 1")

    # Creole1.0: An item ends at blank line
    tc("<ul><li>Item</li></ul><p>Par</p>", "* Item\n\nPar\n")

    # Creole1.0: An item ends at a heading
    tc("<ul><li>Item</li></ul><h1>Heading</h1>", "* Item\n= Heading =\n")

    # Creole1.0: An item ends at a table
    tc("<ul><li>Item</li></ul><table><tr><td>Cell</td></tr></table>", "* Item\n|Cell|\n")

    # Creole1.0: An item ends at a nowiki block
    tc("<ul><li>Item</li></ul><pre>Code</pre>", "* Item\n{{{\nCode\n}}}\n")

    # Creole1.0: An item can span multiple lines
    tc("<ul><li>The quick brown fox jumps over lazy dog.</li><li>Humpty Dumpty sat on a wall.</li></ul>",
       "* The quick\nbrown fox\n\tjumps over\nlazy dog.\n*Humpty Dumpty\nsat\t\non a wall.")

    # Creole1.0: An item can contain line breaks
    tc("<ul><li>The quick brown<br/>fox jumps over lazy dog.</li></ul>",
       "* The quick brown\\\\fox jumps over lazy dog.")

    # Creole1.0: Nested
    tc "<ul><li>Item 1<ul><li>Item 2</li></ul></li><li>Item 3</li></ul>", "* Item 1\n **Item 2\n *\t\tItem 3\n"

    # Creole1.0: Nested up to 5 levels
    tc("<ul><li>Item 1<ul><li>Item 2<ul><li>Item 3<ul><li>Item 4<ul><li>Item 5</li></ul></li></ul></li></ul></li></ul></li></ul>",
       "*Item 1\n**Item 2\n***Item 3\n****Item 4\n*****Item 5\n")

    # Creole1.0: ** immediatly following a list element will be treated as a nested unordered element.
    tc("<ul><li>Hello, World!<ul><li>Not bold</li></ul></li></ul>",
       "*Hello,\nWorld!\n**Not bold\n")

    # Creole1.0: ** immediatly following a list element will be treated as a nested unordered element.
    tc("<ol><li>Hello, World!<ul><li>Not bold</li></ul></li></ol>",
       "#Hello,\nWorld!\n**Not bold\n")

    # Creole1.0: [...] otherwise it will be treated as the beginning of bold text.
    tc("<ul><li>Hello, World!</li></ul><p><strong>Not bold</strong></p>",
       "*Hello,\nWorld!\n\n**Not bold\n")
  end

  it 'should parse ordered lists' do
    # Creole1.0: List items begin with a * at the beginning of a line.
    # Creole1.0: An item ends at the next *
    tc "<ol><li>Item 1</li><li>Item 2</li><li>Item 3</li></ol>", "# Item 1\n #Item 2\n #\t\tItem 3\n"

    # Creole1.0: Whitespace is optional before and after the #.
    tc("<ol><li>Item 1</li><li>Item 2</li><li>Item 3</li></ol>",
       "   #    Item 1\n#Item 2\n \t#\t\tItem 3\n")

    # Creole1.0: A space is required if if the list element starts with bold text.
    tc("<ol><li><ol><li><ol><li>Item 1</li></ol></li></ol></li></ol>", "###Item 1")
    tc("<ol><li><strong>Item 1</strong></li></ol>", "# **Item 1")

    # Creole1.0: An item ends at blank line
    tc("<ol><li>Item</li></ol><p>Par</p>", "# Item\n\nPar\n")

    # Creole1.0: An item ends at a heading
    tc("<ol><li>Item</li></ol><h1>Heading</h1>", "# Item\n= Heading =\n")

    # Creole1.0: An item ends at a table
    tc("<ol><li>Item</li></ol><table><tr><td>Cell</td></tr></table>", "# Item\n|Cell|\n")

    # Creole1.0: An item ends at a nowiki block
    tc("<ol><li>Item</li></ol><pre>Code</pre>", "# Item\n{{{\nCode\n}}}\n")

    # Creole1.0: An item can span multiple lines
    tc("<ol><li>The quick brown fox jumps over lazy dog.</li><li>Humpty Dumpty sat on a wall.</li></ol>",
       "# The quick\nbrown fox\n\tjumps over\nlazy dog.\n#Humpty Dumpty\nsat\t\non a wall.")

    # Creole1.0: An item can contain line breaks
    tc("<ol><li>The quick brown<br/>fox jumps over lazy dog.</li></ol>",
       "# The quick brown\\\\fox jumps over lazy dog.")

    # Creole1.0: Nested
    tc "<ol><li>Item 1<ol><li>Item 2</li></ol></li><li>Item 3</li></ol>", "# Item 1\n ##Item 2\n #\t\tItem 3\n"

    # Creole1.0: Nested up to 5 levels
    tc("<ol><li>Item 1<ol><li>Item 2<ol><li>Item 3<ol><li>Item 4<ol><li>Item 5</li></ol></li></ol></li></ol></li></ol></li></ol>",
       "#Item 1\n##Item 2\n###Item 3\n####Item 4\n#####Item 5\n")

    # Creole1.0_Infered: The two-bullet rule only applies to **.
    tc("<ol><li><ol><li>Item</li></ol></li></ol>", "##Item")
  end

  it 'should parse ordered lists #2' do
    tc "<ol><li>Item 1</li><li>Item 2</li><li>Item 3</li></ol>", "# Item 1\n #Item 2\n #\t\tItem 3\n"
    # Nested
    tc "<ol><li>Item 1<ol><li>Item 2</li></ol></li><li>Item 3</li></ol>", "# Item 1\n ##Item 2\n #\t\tItem 3\n"
    # Multiline
    tc "<ol><li>Item 1 on multiple lines</li></ol>", "# Item 1\non multiple lines"
  end

  it 'should parse ambiguious mixed lists' do
    # ol following ul
    tc("<ul><li>uitem</li></ul><ol><li>oitem</li></ol>", "*uitem\n#oitem\n")

    # ul following ol
    tc("<ol><li>uitem</li></ol><ul><li>oitem</li></ul>", "#uitem\n*oitem\n")

    # 2ol following ul
    tc("<ul><li>uitem<ol><li>oitem</li></ol></li></ul>", "*uitem\n##oitem\n")

    # 2ul following ol
    tc("<ol><li>uitem<ul><li>oitem</li></ul></li></ol>", "#uitem\n**oitem\n")

    # 3ol following 3ul
    tc("<ul><li><ul><li><ul><li>uitem</li></ul><ol><li>oitem</li></ol></li></ul></li></ul>", "***uitem\n###oitem\n")

    # 2ul following 2ol
    tc("<ol><li><ol><li>uitem</li></ol><ul><li>oitem</li></ul></li></ol>", "##uitem\n**oitem\n")

    # ol following 2ol
    tc("<ol><li><ol><li>oitem1</li></ol></li><li>oitem2</li></ol>", "##oitem1\n#oitem2\n")
    # ul following 2ol
    tc("<ol><li><ol><li>oitem1</li></ol></li></ol><ul><li>oitem2</li></ul>", "##oitem1\n*oitem2\n")
  end

  it 'should parse ambiguious italics and url' do
    # Uncommon URL schemes should not be parsed as URLs
    tc("<p>This is what can go wrong:<em>this should be an italic text</em>.</p>",
       "This is what can go wrong://this should be an italic text//.")

    # A link inside italic text
    tc("<p>How about <em>a link, like <a href=\"http://example.org\">http://example.org</a>, in italic</em> text?</p>",
       "How about //a link, like http://example.org, in italic// text?")

    # Another test from Creole Wiki
    tc("<p>Formatted fruits, for example:<em>apples</em>, oranges, <strong>pears</strong> ...</p>",
       "Formatted fruits, for example://apples//, oranges, **pears** ...")
  end

  it 'should parse ambiguious bold and lists' do
    tc "<p><strong> bold text </strong></p>", "** bold text **"
    tc "<p> <strong> bold text </strong></p>", " ** bold text **"
  end

  it 'should parse nowiki' do
    # ... works as block
    tc "<pre>Hello</pre>", "{{{\nHello\n}}}\n"

    # ... works inline
    tc "<p>Hello <tt>world</tt>.</p>", "Hello {{{world}}}."
    tc "<p><tt>Hello</tt> <tt>world</tt>.</p>", "{{{Hello}}} {{{world}}}."

    # Creole1.0: No wiki markup is interpreted inbetween
    tc "<pre>**Hello**</pre>", "{{{\n**Hello**\n}}}\n"

    # Creole1.0: Leading whitespaces are not permitted
    tc("<p> {{{ Hello }}}</p>", " {{{\nHello\n}}}")
    tc("<p>{{{ Hello }}}</p>", "{{{\nHello\n }}}")

    # Assumed: Should preserve whitespace
    tc("<pre> \t Hello, \t \n \t World \t </pre>",
       "{{{\n \t Hello, \t \n \t World \t \n}}}\n")

    # In preformatted blocks ... one leading space is removed
    tc("<pre>nowikiblock\n}}}</pre>", "{{{\nnowikiblock\n }}}\n}}}\n")

    # In inline nowiki, any trailing closing brace is included in the span
    tc("<p>this is <tt>nowiki}</tt></p>", "this is {{{nowiki}}}}")
    tc("<p>this is <tt>nowiki}}</tt></p>", "this is {{{nowiki}}}}}")
    tc("<p>this is <tt>nowiki}}}</tt></p>", "this is {{{nowiki}}}}}}")
    tc("<p>this is <tt>nowiki}}}}</tt></p>", "this is {{{nowiki}}}}}}}")
  end

  it 'should escape html' do
    # Special HTML chars should be escaped
    tc("<p>&lt;b&gt;not bold&lt;/b&gt;</p>", "<b>not bold</b>")

    # Image tags should be escape
    tc("<p><img src=\"image.jpg\" alt=\"&quot;tag&quot;\"/></p>", "{{image.jpg|\"tag\"}}")

    # Malicious links should not be converted.
    tc("<p><a href=\"javascript%3Aalert%28%22Boo%21%22%29\">Click</a></p>", "[[javascript:alert(\"Boo!\")|Click]]")
  end

  it 'should support character escape' do
    tc "<p>** Not Bold **</p>", "~** Not Bold ~**"
    tc "<p>// Not Italic //</p>", "~// Not Italic ~//"
    tc "<p>* Not Bullet</p>", "~* Not Bullet"
    # Following char is not a blank (space or line feed)
    tc "<p>Hello ~ world</p>", "Hello ~ world\n"
    tc "<p>Hello ~ world</p>", "Hello ~\nworld\n"
    # Not escaping inside URLs (Creole1.0 not clear on this)
    tc "<p><a href=\"http://example.org/~user/\">http://example.org/~user/</a></p>", "http://example.org/~user/"

    # Escaping links
    tc "<p>http://www.wikicreole.org/</p>", "~http://www.wikicreole.org/"
  end

  it 'should parse horizontal rule' do
    # Creole: Four hyphens make a horizontal rule
    tc "<hr/>", "----"

    # Creole1.0: Whitespace around them is allowed
    tc "<hr/>", " ----"
    tc "<hr/>", "----  "
    tc "<hr/>", "  ----  "
    tc "<hr/>", " \t ---- \t "

    # Creole1.0: Nothing else than hyphens and whitespace is "allowed"
    tc "<p>foo ----</p>", "foo ----\n"
    tc "<p>---- foo</p>", "---- foo\n"

    # Creole1.0: [...] no whitespace is allowed between them
    tc "<p> -- -- </p>", "  -- --  "
    tc "<p> -- -- </p>", "  --\t--  "
  end

  it 'should parse table' do
    tc "<table><tr><td>Hello, World!</td></tr></table>", "|Hello, World!|"
    # Multiple columns
    tc "<table><tr><td>c1</td><td>c2</td><td>c3</td></tr></table>", "|c1|c2|c3|"
    # Multiple rows
    tc "<table><tr><td>c11</td><td>c12</td></tr><tr><td>c21</td><td>c22</td></tr></table>", "|c11|c12|\n|c21|c22|\n"
    # End pipe is optional
    tc "<table><tr><td>c1</td><td>c2</td><td>c3</td></tr></table>", "|c1|c2|c3"
    # Empty cells
    tc "<table><tr><td>c1</td><td></td><td>c3</td></tr></table>", "|c1||c3"
    # Escaping cell separator
    tc "<table><tr><td>c1|c2</td><td>c3</td></tr></table>", "|c1~|c2|c3"
    # Escape in last cell + empty cell
    tc "<table><tr><td>c1</td><td>c2|</td></tr></table>", "|c1|c2~|"
    tc "<table><tr><td>c1</td><td>c2|</td></tr></table>", "|c1|c2~||"
    tc "<table><tr><td>c1</td><td>c2|</td><td></td></tr></table>", "|c1|c2~|||"
    # Equal sign after pipe make a header
    tc "<table><tr><th>Header</th></tr></table>", "|=Header|"

    tc "<table><tr><td>c1</td><td><a href=\"Link\">Link text</a></td><td><img src=\"Image\" alt=\"Image text\"/></td></tr></table>", "|c1|[[Link|Link text]]|{{Image|Image text}}|"
  end

  it 'should parse following table' do
    # table followed by heading
    tc("<table><tr><td>table</td></tr></table><h1>heading</h1>", "|table|\n=heading=\n")
    tc("<table><tr><td>table</td></tr></table><h1>heading</h1>", "|table|\n\n=heading=\n")
    # table followed by paragraph
    tc("<table><tr><td>table</td></tr></table><p>par</p>", "|table|\npar\n")
    tc("<table><tr><td>table</td></tr></table><p>par</p>", "|table|\n\npar\n")
    # table followed by unordered list
    tc("<table><tr><td>table</td></tr></table><ul><li>item</li></ul>", "|table|\n*item\n")
    tc("<table><tr><td>table</td></tr></table><ul><li>item</li></ul>", "|table|\n\n*item\n")
    # table followed by ordered list
    tc("<table><tr><td>table</td></tr></table><ol><li>item</li></ol>", "|table|\n#item\n")
    tc("<table><tr><td>table</td></tr></table><ol><li>item</li></ol>", "|table|\n\n#item\n")
    # table followed by horizontal rule
    tc("<table><tr><td>table</td></tr></table><hr/>", "|table|\n----\n")
    tc("<table><tr><td>table</td></tr></table><hr/>", "|table|\n\n----\n")
    # table followed by nowiki block
    tc("<table><tr><td>table</td></tr></table><pre>pre</pre>", "|table|\n{{{\npre\n}}}\n")
    tc("<table><tr><td>table</td></tr></table><pre>pre</pre>", "|table|\n\n{{{\npre\n}}}\n")
    # table followed by table
    tc("<table><tr><td>table</td></tr><tr><td>table</td></tr></table>", "|table|\n|table|\n")
    tc("<table><tr><td>table</td></tr></table><table><tr><td>table</td></tr></table>", "|table|\n\n|table|\n")
  end

  it 'should parse following heading' do
    # heading
    tc("<h1>heading1</h1><h1>heading2</h1>", "=heading1=\n=heading2\n")
    tc("<h1>heading1</h1><h1>heading2</h1>", "=heading1=\n\n=heading2\n")
    # paragraph
    tc("<h1>heading</h1><p>par</p>", "=heading=\npar\n")
    tc("<h1>heading</h1><p>par</p>", "=heading=\n\npar\n")
    # unordered list
    tc("<h1>heading</h1><ul><li>item</li></ul>", "=heading=\n*item\n")
    tc("<h1>heading</h1><ul><li>item</li></ul>", "=heading=\n\n*item\n")
    # ordered list
    tc("<h1>heading</h1><ol><li>item</li></ol>", "=heading=\n#item\n")
    tc("<h1>heading</h1><ol><li>item</li></ol>", "=heading=\n\n#item\n")
    # horizontal rule
    tc("<h1>heading</h1><hr/>", "=heading=\n----\n")
    tc("<h1>heading</h1><hr/>", "=heading=\n\n----\n")
    # nowiki block
    tc("<h1>heading</h1><pre>nowiki</pre>", "=heading=\n{{{\nnowiki\n}}}\n")
    tc("<h1>heading</h1><pre>nowiki</pre>", "=heading=\n\n{{{\nnowiki\n}}}\n")
    # table
    tc("<h1>heading</h1><table><tr><td>table</td></tr></table>", "=heading=\n|table|\n")
    tc("<h1>heading</h1><table><tr><td>table</td></tr></table>", "=heading=\n\n|table|\n")
  end

  it 'should parse following paragraph' do
    # heading
    tc("<p>par</p><h1>heading</h1>", "par\n=heading=")
    tc("<p>par</p><h1>heading</h1>", "par\n\n=heading=")
    # paragraph
    tc("<p>par par</p>", "par\npar\n")
    tc("<p>par</p><p>par</p>", "par\n\npar\n")
    # unordered
    tc("<p>par</p><ul><li>item</li></ul>", "par\n*item")
    tc("<p>par</p><ul><li>item</li></ul>", "par\n\n*item")
    # ordered
    tc("<p>par</p><ol><li>item</li></ol>", "par\n#item\n")
    tc("<p>par</p><ol><li>item</li></ol>", "par\n\n#item\n")
    # horizontal
    tc("<p>par</p><hr/>", "par\n----\n")
    tc("<p>par</p><hr/>", "par\n\n----\n")
    # nowiki
    tc("<p>par</p><pre>nowiki</pre>", "par\n{{{\nnowiki\n}}}\n")
    tc("<p>par</p><pre>nowiki</pre>", "par\n\n{{{\nnowiki\n}}}\n")
    # table
    tc("<p>par</p><table><tr><td>table</td></tr></table>", "par\n|table|\n")
    tc("<p>par</p><table><tr><td>table</td></tr></table>", "par\n\n|table|\n")
  end

  it 'should parse following unordered list' do
    # heading
    tc("<ul><li>item</li></ul><h1>heading</h1>", "*item\n=heading=")
    tc("<ul><li>item</li></ul><h1>heading</h1>", "*item\n\n=heading=")
    # paragraph
    tc("<ul><li>item par</li></ul>", "*item\npar\n") # items may span multiple lines
    tc("<ul><li>item</li></ul><p>par</p>", "*item\n\npar\n")
    # unordered
    tc("<ul><li>item</li><li>item</li></ul>", "*item\n*item\n")
    tc("<ul><li>item</li></ul><ul><li>item</li></ul>", "*item\n\n*item\n")
    # ordered
    tc("<ul><li>item</li></ul><ol><li>item</li></ol>", "*item\n#item\n")
    tc("<ul><li>item</li></ul><ol><li>item</li></ol>", "*item\n\n#item\n")
    # horizontal rule
    tc("<ul><li>item</li></ul><hr/>", "*item\n----\n")
    tc("<ul><li>item</li></ul><hr/>", "*item\n\n----\n")
    # nowiki
    tc("<ul><li>item</li></ul><pre>nowiki</pre>", "*item\n{{{\nnowiki\n}}}\n")
    tc("<ul><li>item</li></ul><pre>nowiki</pre>", "*item\n\n{{{\nnowiki\n}}}\n")
    # table
    tc("<ul><li>item</li></ul><table><tr><td>table</td></tr></table>", "*item\n|table|\n")
    tc("<ul><li>item</li></ul><table><tr><td>table</td></tr></table>", "*item\n\n|table|\n")
  end

  it 'should parse following ordered list' do
    # heading
    tc("<ol><li>item</li></ol><h1>heading</h1>", "#item\n=heading=")
    tc("<ol><li>item</li></ol><h1>heading</h1>", "#item\n\n=heading=")
    # paragraph
    tc("<ol><li>item par</li></ol>", "#item\npar\n") # items may span multiple lines
    tc("<ol><li>item</li></ol><p>par</p>", "#item\n\npar\n")
    # unordered
    tc("<ol><li>item</li></ol><ul><li>item</li></ul>", "#item\n*item\n")
    tc("<ol><li>item</li></ol><ul><li>item</li></ul>", "#item\n\n*item\n")
    # ordered
    tc("<ol><li>item</li><li>item</li></ol>", "#item\n#item\n")
    tc("<ol><li>item</li></ol><ol><li>item</li></ol>", "#item\n\n#item\n")
    # horizontal role
    tc("<ol><li>item</li></ol><hr/>", "#item\n----\n")
    tc("<ol><li>item</li></ol><hr/>", "#item\n\n----\n")
    # nowiki
    tc("<ol><li>item</li></ol><pre>nowiki</pre>", "#item\n{{{\nnowiki\n}}}\n")
    tc("<ol><li>item</li></ol><pre>nowiki</pre>", "#item\n\n{{{\nnowiki\n}}}\n")
    # table
    tc("<ol><li>item</li></ol><table><tr><td>table</td></tr></table>", "#item\n|table|\n")
    tc("<ol><li>item</li></ol><table><tr><td>table</td></tr></table>", "#item\n\n|table|\n")
  end

  it 'should parse following horizontal rule' do
    # heading
    tc("<hr/><h1>heading</h1>", "----\n=heading=")
    tc("<hr/><h1>heading</h1>", "----\n\n=heading=")
    # paragraph
    tc("<hr/><p>par</p>", "----\npar\n")
    tc("<hr/><p>par</p>", "----\n\npar\n")
    # unordered
    tc("<hr/><ul><li>item</li></ul>", "----\n*item")
    tc("<hr/><ul><li>item</li></ul>", "----\n*item")
    # ordered
    tc("<hr/><ol><li>item</li></ol>", "----\n#item")
    tc("<hr/><ol><li>item</li></ol>", "----\n#item")
    # horizontal
    tc("<hr/><hr/>", "----\n----\n")
    tc("<hr/><hr/>", "----\n\n----\n")
    # nowiki
    tc("<hr/><pre>nowiki</pre>", "----\n{{{\nnowiki\n}}}\n")
    tc("<hr/><pre>nowiki</pre>", "----\n\n{{{\nnowiki\n}}}\n")
    # table
    tc("<hr/><table><tr><td>table</td></tr></table>", "----\n|table|\n")
    tc("<hr/><table><tr><td>table</td></tr></table>", "----\n\n|table|\n")
  end

  it 'should parse following nowiki block' do
    # heading
    tc("<pre>nowiki</pre><h1>heading</h1>", "{{{\nnowiki\n}}}\n=heading=")
    tc("<pre>nowiki</pre><h1>heading</h1>", "{{{\nnowiki\n}}}\n\n=heading=")
    # paragraph
    tc("<pre>nowiki</pre><p>par</p>", "{{{\nnowiki\n}}}\npar")
    tc("<pre>nowiki</pre><p>par</p>", "{{{\nnowiki\n}}}\n\npar")
    # unordered
    tc("<pre>nowiki</pre><ul><li>item</li></ul>", "{{{\nnowiki\n}}}\n*item\n")
    tc("<pre>nowiki</pre><ul><li>item</li></ul>", "{{{\nnowiki\n}}}\n\n*item\n")
    # ordered
    tc("<pre>nowiki</pre><ol><li>item</li></ol>", "{{{\nnowiki\n}}}\n#item\n")
    tc("<pre>nowiki</pre><ol><li>item</li></ol>", "{{{\nnowiki\n}}}\n\n#item\n")
    # horizontal
    tc("<pre>nowiki</pre><hr/>", "{{{\nnowiki\n}}}\n----\n")
    tc("<pre>nowiki</pre><hr/>", "{{{\nnowiki\n}}}\n\n----\n")
    # nowiki
    tc("<pre>nowiki</pre><pre>nowiki</pre>", "{{{\nnowiki\n}}}\n{{{\nnowiki\n}}}\n")
    tc("<pre>nowiki</pre><pre>nowiki</pre>", "{{{\nnowiki\n}}}\n\n{{{\nnowiki\n}}}\n")
    # table
    tc("<pre>nowiki</pre><table><tr><td>table</td></tr></table>", "{{{\nnowiki\n}}}\n|table|\n")
    tc("<pre>nowiki</pre><table><tr><td>table</td></tr></table>", "{{{\nnowiki\n}}}\n\n|table|\n")
  end

  it 'should parse image' do
    tc("<p><img src=\"image.jpg\"/></p>", "{{image.jpg}}")
    tc("<p><img src=\"image.jpg\" alt=\"tag\"/></p>", "{{image.jpg|tag}}")
    tc("<p><img src=\"http://example.org/image.jpg\"/></p>", "{{http://example.org/image.jpg}}")
  end

  it 'should parse bold combo' do
    tc("<p><strong>bold and</strong></p><table><tr><td>table</td></tr></table><p>end<strong></strong></p>",
       "**bold and\n|table|\nend**")
  end

  it 'should support extensions' do
    tc("<p>This is not __underlined__</p>",
       "This is not __underlined__")

    tce("<p>This is <u>underlined</u></p>",
        "This is __underlined__")

    tce("<p>This is <del>deleted</del></p>",
        "This is --deleted--")

    tce("<p>This is <ins>inserted</ins></p>",
        "This is ++inserted++")

    tce("<p>This is <sup>super</sup></p>",
        "This is ^^super^^")

    tce("<p>This is <sub>sub</sub></p>",
        "This is ~~sub~~")

    tce("<p>&#174;</p>", "(R)")
    tce("<p>&#174;</p>", "(r)")
    tce("<p>&#169;</p>", "(C)")
    tce("<p>&#169;</p>", "(c)")
  end

  it 'should support no_escape' do
    tc("<p><a href=\"a%2Fb%2Fc\">a/b/c</a></p>", "[[a/b/c]]")
    tc("<p><a href=\"a/b/c\">a/b/c</a></p>", "[[a/b/c]]", :no_escape => true)
  end
end
