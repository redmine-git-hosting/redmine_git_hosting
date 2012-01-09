class GitolitePublicKeysController < ApplicationController
	unloadable

	before_filter :require_login
	before_filter :set_user_variable
	before_filter :find_gitolite_public_key, :except => [:index, :new, :create]


	def edit
        	redirect_to url_for(:controller=>'my', :action=>'account', :public_key_id => @gitolite_public_key[:id])
	end

	def destroy
        	GitHostingObserver.set_update_active(false)
        	if !request.get?
                	destroy_key
                end
        	redirect_to url_for(:controller => 'my', :action => 'account')
        	GitHostingObserver.set_update_active(true)
	end

	def update
        	GitHostingObserver.set_update_active(false)
        	if !request.get?
                	if params[:save_button] && @gitolite_public_key.update_attributes(params[:public_key])
                		@gitolite_public_key.save
				flash[:notice] = l(:notice_public_key_updated, :title=>@gitolite_public_key[:title])
                	elsif params[:delete_button]
                        	destroy_key
                	end
                end
        	redirect_to url_for(:controller => 'my', :action => 'account')
        	GitHostingObserver.set_update_active(true)
	end

	def create
        	GitHostingObserver.set_update_active(false)
		@gitolite_public_key = GitolitePublicKey.new(params[:public_key].merge(:user => @user))
		if @gitolite_public_key.save
			flash[:notice] = l(:notice_public_key_added, :title=>@gitolite_public_key[:title])
		else
			@gitolite_public_key = GitolitePublicKey.new(:user => @user)
		end
		redirect_to url_for(:controller => 'my', :action => 'account')
        	GitHostingObserver.set_update_active(true)
	end

	protected

	def set_user_variable
		@user = User.current
	end

	def find_gitolite_public_key
		key = GitolitePublicKey.find_by_id(params[:id])
		if key and key.user == @user
			@gitolite_public_key = key
		elsif key
			render_403
		else
			render_404
		end
	end

        def destroy_key
        	@gitolite_public_key[:active] = 0
        	@gitolite_public_key.save
                flash[:notice] = l(:notice_public_key_deleted, :title=>@gitolite_public_key[:title])
        end
end
