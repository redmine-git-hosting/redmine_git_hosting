class GitolitePublicKeysController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :set_user_variable
  before_filter :set_users_keys, :except => [:index, :new, :reset_rss_key]
  before_filter :find_gitolite_public_key, :except => [:index, :new, :reset_rss_key, :create]

  helper :issues
  helper :users
  helper :custom_fields

  helper :gitolite_public_keys


  def create
    @gitolite_public_key = GitolitePublicKey.new(params[:gitolite_public_key].merge(:user => @user))

    if params[:create_button]
      if @gitolite_public_key.save
        flash[:notice] = l(:notice_public_key_created, :title => view_context.keylabel(@gitolite_public_key))

        respond_to do |format|
          format.html { redirect_to @redirect_url }
        end
      else
        flash[:error] = @gitolite_public_key.errors.full_messages.to_sentence

        respond_to do |format|
          format.html { redirect_to @redirect_url }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @redirect_url }
      end
    end
  end


  def destroy
    if request.delete?
      if @gitolite_public_key.destroy
        flash[:notice] = l(:notice_public_key_deleted, :title => view_context.keylabel(@gitolite_public_key))
      end
      redirect_to @redirect_url
    end
  end


  private


  def set_user_variable
    if params[:user_id]
      @user = (params[:user_id] == 'current') ? User.current : User.find_by_id(params[:user_id])
      if @user
        @redirect_url = url_for(:controller => 'users', :action => 'edit', :id => params[:user_id], :tab => 'keys')
      else
        render_404
      end
    else
      @user = User.current
      @redirect_url = url_for(:controller => 'my', :action => 'account')
    end
  end


  def set_users_keys
    @gitolite_user_keys   = @user.gitolite_public_keys.user_key.order('title ASC, created_at ASC')
    @gitolite_deploy_keys = @user.gitolite_public_keys.deploy_key.order('title ASC, created_at ASC')
  end


  def find_gitolite_public_key
    key = GitolitePublicKey.find_by_id(params[:id])
    if key && (@user == key.user || @user.admin?)
      @gitolite_public_key = key
    elsif key
      render_403
    else
      render_404
    end
  end

end
