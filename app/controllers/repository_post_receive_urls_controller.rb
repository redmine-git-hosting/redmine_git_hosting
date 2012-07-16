class RepositoryPostReceiveUrlsController < ApplicationController
    unloadable

    before_filter :require_login
    before_filter :set_user_variable
    before_filter :set_project_variable
    before_filter :check_required_permissions
    before_filter :check_xhr_request
    before_filter :find_repository_post_receive_url, :except => [:index, :create]
    
    menu_item :settings, :only => :settings
    
    layout Proc.new { |controller| controller.request.xhr? ? 'popup' : 'base' }
    
    def index
        render_404
    end
    
    def create
        @prurl = RepositoryPostReceiveUrl.new(params[:repository_post_receive_urls])
        if request.get?
            # display create view
        else
            @prurl.update_attributes(params[:repository_post_receive_urls])
            @prurl.project = @project
            
            if @prurl.save
                flash[:notice] = l(:post_receive_url_notice_created)
                redirect_url = url_for(:controller => 'projects', 
                                       :action => 'settings', 
                                       :id => @prurl.project.identifier, 
                                       :tab => 'repository')
                
                respond_to do |format|
                    format.html { 
                        redirect_to redirect_url
                    }
                    format.js { 				
                        render :update do |page|
                            page.redirect_to redirect_url
                        end
                    }
                end
            else
                respond_to do |format|
                    format.html { 
                        flash[:error] = l(:post_receive_url_notice_create_failed)
                        render :action => "create" 
                    }
                    format.js {                			
                        render :action => "form_error"
                    }
                end
            end
        end
    end
    
    def edit
    end

    def update
        if @prurl.update_attributes(params[:repository_post_receive_urls])
            flash[:notice] = l(:post_receive_url_notice_updated)
            redirect_url = url_for(:controller => 'projects', 
                                   :action => 'settings', 
                                   :id => @prurl.project.identifier, 
                                   :tab => 'repository')
            
            respond_to do |format|
                format.html { 
                    redirect_to redirect_url
                }
                format.js { 				
                    render :update do |page|
                        page.redirect_to redirect_url
                    end
                }
            end
        else
            respond_to do |format|                	
                format.html { 
                    flash[:error] = l(:post_receive_url_notice_update_failed)
                    render :action => "edit" 
                }
                format.js {                			
                    render :action => "form_error"
                }
                
            end
        end
    end
    
    def destroy
        if request.get?
            # display confirmation view
        else
            if params[:confirm]
                redirect_url = url_for(:controller => 'projects',
                                       :action => 'settings',
                                       :id => @prurl.project.identifier,
                                       :tab => 'repository')
                @prurl.destroy
                respond_to do |format|
                    format.html {redirect_to(redirect_url, :notice => l(:post_receive_url_notice_deleted))}
                end
            end
        end
    end
    
    def settings
    end
    
    protected


    def set_user_variable
        @user = User.current
    end
    
    def set_project_variable
        @project = Project.find(:first, :conditions => ["identifier = ?", params[:project_id]])
    end

    def find_repository_post_receive_url
        prurl = RepositoryPostReceiveUrl.find_by_id(params[:id])
        
        @prurls = @project.repository_post_receive_urls
        
        if prurl and prurl.project == @project
            @prurl = prurl
        elsif prurl
            render_403
        else
            render_404
        end
    end
    
    def check_required_permissions
        # Deny access if the curreent user is not allowed to manage the project's repositoy
        if not @project.module_enabled?(:repository)
            render_403
        end
        not_enough_perms = true
        @user.roles_for_project(@project).each{|role|
            if role.allowed_to? :manage_repository
                not_enough_perms = false
                break
            end
        }
        if not_enough_perms
            render_403
        end
    end
    
    def check_xhr_request
        @is_xhr ||= request.xhr?
    end

end
