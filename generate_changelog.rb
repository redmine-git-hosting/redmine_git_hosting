#!/usr/bin/env ruby

require 'yaml'

DIR = File.join(Dir.pwd, '_posts', 'releases', '*.md')
DEST_FILE = File.join(Dir.pwd, 'CHANGELOG.md')

class RelaseFile

  attr_reader :path

  def initialize(path)
    @path = path
    puts "Loading file : '#{file_name}' :"
  end

  def file_name
    File.basename(path)
  end

  def yml_content
    @yml ||= YAML::load(File.read(path))
  end

  def title
    yml_content['title']
  end

  def version
    yml_content['version']
  end

  def date
    file_name.match(/\A(\d*\-\d*\-\d*)\-release\-.*\z/)[1]
  end

  def file_content
    @content ||= File.read(path)
  end

  def markdown_content
    file_content.match(/\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)(.*)/m)[4]
  end

  def write_content(dest_file)
    File.open(dest_file, 'a') do |f|
      f.write "## #{version} - #{date}\n\n"
      f.write markdown_content
      f.write "\n"
    end
  end
end

def load_release_file(file)
  file = RelaseFile.new(file)
  puts "  - Title   : #{file.title}"
  puts "  - Version : #{file.version}"
  puts "  - Date    : #{file.date}"
  puts ''
  file
end


Dir[DIR].sort.reverse.each do |file|
  file = load_release_file(file)
  file.write_content(DEST_FILE)
end
