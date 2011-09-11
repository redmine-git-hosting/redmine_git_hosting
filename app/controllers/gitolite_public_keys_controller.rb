class GitolitePublicKeysController < ApplicationController
	unloadable

	before_filter :require_login
	before_filter :set_user_variable
	before_filter :find_gitolite_public_key, :except => [:index, :new, :create]


	def edit
	end

	def delete
		@gitolite_public_key[:active] = 0
		@gitolite_public_key.save
		redirect_to url_for(:controller => 'my', :action => 'account')
	end

	def update
		if @gitolite_public_key.update_attributes(params[:public_key])
			flash[:notice] = l(:notice_public_key_updated)
			redirect_to url_for(:controller => 'my', :action => 'account')
		else
			render :action => 'edit'
		end
	end

	def create
		@gitolite_public_key = GitolitePublicKey.new(params[:public_key].merge(:user => @user))
		if @gitolite_public_key.save
			flash[:notice] = l(:notice_public_key_added)
		else
			@gitolite_public_key = GitolitePublicKey.new(:user => @user)
		end
		redirect_to url_for(:controller => 'my', :action => 'account')
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

end
