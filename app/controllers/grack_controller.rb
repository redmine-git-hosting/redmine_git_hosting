class GrackController < ApplicationController
  
  def index
    render :text=>"<html><body>p1=" + params[:p1] + "<br>p2=" + params[:p2] + "<br>p3=" + params[:p3] + "</body></body>\n"

  end
  

end
