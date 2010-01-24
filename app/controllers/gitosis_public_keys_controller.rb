class GitosisPublicKeysController < ApplicationController

  before_filter :require_login
  before_filter :set_user_variable
  before_filter :find_gitosis_public_key, :except => [:index, :new, :create]

  def index
    @status = if (session[:gitosis_public_key_filter_status]=params[:status]).nil?
      GitosisPublicKey::STATUS_ACTIVE
    elsif params[:status].blank?
        nil
    else 
      params[:status].to_i
    end
    c = ARCondition.new(@status ? ["active=?", @status] : nil)

    @gitosis_public_keys = @user.gitosis_public_keys.all(:order => 'active DESC, created_at DESC', :conditions => c.conditions)
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @gitosis_public_keys }
    end
  end
  
  def edit
  end

  def update
    if @gitosis_public_key.update_attributes(params[:public_key])
      flash[:notice] = l(:notice_public_key_updated)
      redirect_to url_for(:action => 'index', :status => session[:gitosis_public_key_filter_status])
    else
      render :action => 'edit'
    end
  end
  
  def new
    @gitosis_public_key = GitosisPublicKey.new(:user => @user)
  end
  
  def create
    @gitosis_public_key = GitosisPublicKey.new(params[:public_key].merge(:user => @user))
    if @gitosis_public_key.save
      flash[:notice] = l(:notice_public_key_added)
      redirect_to url_for(:action => 'index', :status => session[:gitosis_public_key_filter_status])
    else
      render :action => 'new'
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @gitosis_public_key }
    end
  end
  
  protected
  
  def set_user_variable
    @user = User.current
  end
  
  def find_gitosis_public_key
    key = GitosisPublicKey.find_by_id(params[:id])
    if key and key.user == @user
      @gitosis_public_key = key
    elsif key
      render_403
    else
      render_404
    end
  end

end