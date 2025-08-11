= RubyPants: SmartyPants for Ruby

{<img src="https://img.shields.io/gem/v/rubypants.svg?maxAge=2592000&style=plastic" alt="Gem">}[https://rubygems.org/gems/rubypants]
{<img src="https://img.shields.io/travis/jmcnevin/rubypants.svg?maxAge=2592000&style=plastic" alt="Travis">}[https://travis-ci.org/jmcnevin/rubypants]
{<img src="https://img.shields.io/codecov/c/github/jmcnevin/rubypants.svg?maxAge=2592000&style=plastic" alt="CodeCov">}[https://codecov.io/gh/jmcnevin/rubypants]

== Synopsis

RubyPants is a Ruby port of the smart-quotes library SmartyPants.

The original "SmartyPants" is a free web publishing plug-in for
Movable Type, Blosxom, and BBEdit that easily translates plain ASCII
punctuation characters into "smart" typographic punctuation HTML
entities.


== Description

RubyPants can perform the following transformations:

* Straight quotes (<tt>"</tt> and <tt>'</tt>) into "curly" quote
  HTML entities
* Backticks-style quotes (<tt>``like this''</tt>) into "curly" quote
  HTML entities
* Dashes (<tt>--</tt> and <tt>---</tt>) into en- and em-dash
  entities
* Three consecutive dots (<tt>...</tt> or <tt>. . .</tt>) into an
  ellipsis entity

This means you can write, edit, and save your posts using plain old
ASCII straight quotes, plain dashes, and plain dots, but your
published posts (and final HTML output) will appear with smart
quotes, em-dashes, and proper ellipses.

RubyPants does not modify characters within <tt><pre></tt>,
<tt><code></tt>, <tt><kbd></tt>, <tt><math></tt>, <tt><style></tt> or
<tt><script></tt> tag blocks. Typically, these tags are used to
display text where smart quotes and other "smart punctuation" would
not be appropriate, such as source code or example markup.


== Installation

  gem install rubypants

Or, in your application's Gemfile:

  gem 'rubypants'


== Example of Usage

  RubyPants.new("String with 'dumb' quotes.").to_html

For additional options, consult the documention in
<tt>lib/rubypants/core.rb</tt>.


== Backslash Escapes

If you need to use literal straight quotes (or plain hyphens and
periods), RubyPants accepts the following backslash escape sequences
to force non-smart punctuation. It does so by transforming the
escape sequence into a decimal-encoded HTML entity:

  \\    \"    \'    \.    \-    \`

This is useful, for example, when you want to use straight quotes as
foot and inch marks: 6'2" tall; a 17" iMac.  (Use <tt>6\'2\"</tt>
resp. <tt>17\"</tt>.)


== Algorithmic Shortcomings

One situation in which quotes will get curled the wrong way is when
apostrophes are used at the start of leading contractions. For
example:

  'Twas the night before Christmas.

In the case above, RubyPants will turn the apostrophe into an
opening single-quote, when in fact it should be a closing one. I
don't think this problem can be solved in the general case--every
word processor I've tried gets this wrong as well. In such cases,
it's best to use the proper HTML entity for closing single-quotes
("<tt>&#8217;</tt>") by hand.


== Bugs

To file bug reports or feature requests, please create an issue in this gem's
GitHub repository.

If the bug involves quotes being curled the wrong way, please send
example text to illustrate.


== Authors

John Gruber did all of the hard work of writing this software in
Perl for Movable Type and almost all of this useful documentation.
Chad Miller ported it to Python to use with Pyblosxom.

Christian Neukirchen provided the Ruby port, as a general-purpose
library that follows the *Cloth API.

Jeremy McNevin posted this code to GitHub ages ago, but has recently
been trying to improve it where possible.

Aron Griffis made jekyll-pants[https://github.com/scampersand/jekyll-pants]
which depends on RubyPants, and consequently jumped in to help out with
issues and pull requests.


== Links

John Gruber :: http://daringfireball.net
SmartyPants :: http://daringfireball.net/projects/smartypants
Chad Miller :: http://web.chad.org
Christian Neukirchen :: http://kronavita.de/chris
Aron Griffis :: https://arongriffis.com
