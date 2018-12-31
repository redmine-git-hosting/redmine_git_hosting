class GoRedirectorController < ApplicationController

  include XitoliteRepositoryFinder

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_action :check_if_login_required, :verify_authenticity_token

  before_action :find_xitolite_repository_by_path


  def index
  end

end
