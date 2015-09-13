class ReportBase
  unloadable

  include Redmine::I18n
  include ReportHelper
  include ReportQuery

  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

end
