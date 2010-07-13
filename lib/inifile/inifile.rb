require 'inifile'
require 'orderedhash'
# let's make the inifile use ordered hash.
# This way the [gitosis] section stays on the top

#
# This class represents the INI file and can be used to parse, modify,
# and write INI files.
#

class IniFile
  #
  # call-seq:
  #    IniFile.new( filename )
  #    IniFile.new( filename, options )
  #
  # Create a new INI file using the given _filename_. If _filename_
  # exists and is a regular file, then its contents will be parsed.
  # The following _options_ can be passed to this method:
  #
  #    :comment => ';'      The line comment character(s)
  #    :parameter => '='    The parameter / value separator
  #
  def initialize( filename, opts = {} )
    @fn = filename
    @comment = opts[:comment] || ';#'
    @param = opts[:parameter] || '='
    @ini = OrderedHash.new {|h,k| h[k] = OrderedHash.new}

    @rgxp_comment = %r/\A\s*\z|\A\s*[#{@comment}]/
    @rgxp_section = %r/\A\s*\[([^\]]+)\]/o
    @rgxp_param   = %r/\A([^#{@param}]+)#{@param}(.*)\z/

    parse
  end
end