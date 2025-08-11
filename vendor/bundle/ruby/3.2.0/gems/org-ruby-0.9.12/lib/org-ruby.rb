$:.unshift File.dirname(__FILE__) # For use/testing when no gem is installed

# internal requires
require 'org-ruby/version'
require 'org-ruby/parser'
require 'org-ruby/regexp_helper'
require 'org-ruby/line'
require 'org-ruby/headline'
require 'org-ruby/output_buffer'

# HTML exporter
require 'org-ruby/html_output_buffer'
require 'org-ruby/html_symbol_replace'

# Textile exporter
require 'org-ruby/textile_output_buffer'
require 'org-ruby/textile_symbol_replace'

# Markdown exporter
require 'org-ruby/markdown_output_buffer'

# Tilt support
require 'org-ruby/tilt'

module OrgRuby

  # :stopdoc:
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Utility method used to require all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
        ::File.join(::File.dirname(fname), dir, '**', '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end

end
