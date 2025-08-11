require 'creole/parser'
require 'creole/version'

module Creole
  # Convert the argument in Creole format to HTML and return the
  # result. Example:
  #
  #    Creole.creolize("**Hello //World//**")
  #        #=> "<p><strong>Hello <em>World</em></strong></p>"
  #
  # This is an alias for calling Creole#parse:
  #    Creole.new(text).to_html
  def self.creolize(text, options = {})
    Parser.new(text, options).to_html
  end
end
