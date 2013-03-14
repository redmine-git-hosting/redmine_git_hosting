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
  include GitolitePublicKeysHelper

  def edit
    redirect_to url_for(:controller=>'my', :action=>'account', :public_key_id => @gitolite_public_key[:id])
  end

  def destroy
    GitHostingObserver.set_update_active(false)
    if !request.get?
      destroy_key
    end
    redirect_to @redirect_url
    GitHostingObserver.set_update_active(true)
  end

  def update
    GitHostingObserver.set_update_active(false)
    if !request.get?
      if params[:save_button]
        if @gitolite_public_key.update_attributes(params[:public_key])
          flash[:notice] = l(:notice_public_key_updated, :title=>keylabel(@gitolite_public_key))

          respond_to do |format|
            format.html { redirect_to @redirect_url }
            format.js { render :update do |page| page.redirect_to @redirect_url end }
          end
        else
          respond_to do |format|
            format.html {
              flash[:error] = l(:error_public_key_create_failed)
              # This doesn't give back validation errors (messy!)
              redirect_to @redirect_url
            }
            format.js {
              render :action => "form_error"
            }
          end
        end
      else
        destroy_key if params[:delete_button]

        respond_to do |format|
          format.html { redirect_to @redirect_url }
          format.js { render :update do |page| page.redirect_to @redirect_url end }
        end
      end
    end
    GitHostingObserver.set_update_active(true)
  end

  def create
    GitHostingObserver.set_update_active(false)
    @gitolite_public_key = GitolitePublicKey.new(params[:public_key].merge(:user => @user))
    if params[:create_button]
      if @gitolite_public_key.save
        flash[:notice] = l(:notice_public_key_added, :title=>keylabel(@gitolite_public_key))

        respond_to do |format|
          format.html { redirect_to @redirect_url }
          format.js { render :update do |page| page.redirect_to @redirect_url end }
        end
      else
        respond_to do |format|
          format.html {
            flash[:error] = l(:error_public_key_create_failed)
            # This doesn't give back validation errors (messy!)
            redirect_to @redirect_url
          }
          format.js {
            render :action => "form_error"
          }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @redirect_url }
        format.js { render :update do |page| page.redirect_to @redirect_url end }
      end
    end
    GitHostingObserver.set_update_active(true)
  end

  protected

  def set_user_variable
    if params[:user_id]
      @user = (params[:user_id]=='current') ? User.current : User.find_by_id(params[:user_id])
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
    @gitolite_user_keys = @user.gitolite_public_keys.active.user_key.find(:all,:order => 'title ASC, created_at ASC')
    @gitolite_deploy_keys = @user.gitolite_public_keys.active.deploy_key.find(:all,:order => 'title ASC, created_at ASC')
    @gitolite_public_keys = @gitolite_user_keys + @gitolite_deploy_keys
  end

  def find_gitolite_public_key
    key = GitolitePublicKey.find_by_id(params[:id])
    if key and (@user == key.user || @user.admin?)
      @gitolite_public_key = key
    elsif key
      render_403
    else
      render_404
    end
  end

  def destroy_key
    @gitolite_public_key[:active] = 0

    # Since we are ultimately destroying this key, just force save (since old keys may fail new validations)
    @gitolite_public_key.save((Rails::VERSION::STRING.split('.')[0].to_i > 2) ? { :validate => false } : false)

    flash[:notice] = l(:notice_public_key_deleted, :title=>keylabel(@gitolite_public_key))
  end
end
