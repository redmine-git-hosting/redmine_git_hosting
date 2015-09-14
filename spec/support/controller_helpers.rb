module ControllerHelpers

  def set_session_user(user)
    request.session[:user_id] = user.id
  end

end
