module CrudControllerSpec
  module Base
    extend ActiveSupport::Concern

    included do
      include CrudControllerSpec::Helpers

      before(:all) do
        @project        = create_project('git_project')
        @repository     = find_or_create_git_repository(project: @project, identifier: 'git_repository')
        @repository2    = find_or_create_git_repository(project: @project, identifier: 'git_repository2')
        @member_user    = create_user_with_permissions(@project, member_user_options)
        @anonymous_user = create_anonymous_user
        @object         = create_object
      end

      describe 'GET #index' do
        context 'with sufficient permissions' do
          before(:each) { set_session_user(@member_user) }

          it 'renders the :index view' do
            check_index_template
          end
        end

        context 'with unsufficient permissions' do
          it 'renders 403' do
            set_session_user(@anonymous_user)
            check_index_status(403)
          end
        end
      end unless respond_to?(:skip_actions) && skip_actions.include?('index')

      describe 'GET #show' do
        before { Setting.rest_api_enabled = 1 }

        context 'with sufficient permissions' do
          it 'renders 200' do
            check_api_response(200, id: @object.id, key: @member_user.api_key)
          end
        end

        context 'with unsufficient permissions' do
          it 'renders 403' do
            check_api_response(403, id: @object.id, key: @anonymous_user.api_key)
          end
        end
      end unless respond_to?(:skip_actions) && skip_actions.include?('show')

      describe 'GET #new' do
        context 'with sufficient permissions' do
          before(:each) { set_session_user(@member_user) }

          it 'assigns a new @object variable' do
            check_new_variable(main_variable, tested_klass)
          end

          it 'renders the :new template' do
            check_new_template
          end
        end

        context 'with unsufficient permissions' do
          it 'renders 403' do
            set_session_user(@anonymous_user)
            check_new_status(403)
          end
        end
      end unless respond_to?(:skip_actions) && skip_actions.include?('new')

      describe 'POST #create' do
        context 'with sufficient permissions' do
          before(:each) do
            set_session_user(@member_user)
            allow(controller).to receive(:call_use_case)
          end

          context 'with valid attributes' do
            it 'saves the new object in the database' do
              check_counter_incremented_on_create(tested_klass, valid_params_for_create)
            end

            it 'redirects to the repository page' do
              check_create_status(200, valid_params_for_create)
            end
          end

          context 'with invalid attributes' do
            it 'does not save the new object in the database' do
              check_counter_not_changed_on_create(tested_klass, invalid_params_for_create)
            end

            it 're-renders the :new template' do
              check_create_template(:create, invalid_params_for_create)
            end
          end
        end

        context 'with unsufficient permissions' do
          it 'renders 403' do
            set_session_user(@anonymous_user)
            check_create_status(403, valid_params_for_create)
          end
        end
      end unless respond_to?(:skip_actions) && skip_actions.include?('create')

      describe 'GET #edit' do
        context 'with sufficient permissions' do
          before(:each) { set_session_user(@member_user) }

          context 'with existing object' do
            it 'assigns the requested object to @object' do
              check_edit_variable(main_variable, @object, id: @object.id)
            end

            it 'renders the :edit template' do
              check_edit_template(id: @object.id)
            end
          end

          context 'with non-existing object' do
            it 'renders 404' do
              check_edit_status(404, id: 100)
            end
          end

          context 'with non-matching repository' do
            it 'renders 404' do
              check_edit_status(404, repository_id: @repository2.id, id: @object.id)
            end
          end

          context 'with non-existing repository' do
            it 'renders 404' do
              check_edit_status(404, repository_id: 345, id: @object.id)
            end
          end
        end

        context 'with unsufficient permissions' do
          it 'renders 403' do
            set_session_user(@anonymous_user)
            check_edit_status(403, id: @object.id)
          end
        end
      end unless respond_to?(:skip_actions) && skip_actions.include?('edit')

      describe 'PUT #update' do
        context 'with sufficient permissions' do
          before(:each) do
            set_session_user(@member_user)
            allow(controller).to receive(:call_use_case)
          end

          context 'with valid attributes' do
            it 'located the requested @object' do
              check_update_variable(main_variable, @object, valid_params_for_update)
            end

            it 'changes @object attributes' do
              check_attribute_has_changed(updated_attribute, updated_attribute_value, valid_params_for_update)
            end

            it 'redirects to the repository page' do
              check_update_status(200, valid_params_for_update)
            end
          end

          context 'with invalid attributes' do
            it 'located the requested @object' do
              check_update_variable(main_variable, @object, invalid_params_for_update)
            end

            it 'does not change @object attributes' do
              check_attribute_has_not_changed(updated_attribute, invalid_params_for_update)
            end

            it 're-renders the :edit template' do
              check_update_template(invalid_params_for_update)
            end
          end
        end

        context 'with unsufficient permissions' do
          it 'renders 403' do
            set_session_user(@anonymous_user)
            check_update_status(403, valid_params_for_update)
          end
        end
      end unless respond_to?(:skip_actions) && skip_actions.include?('update')

      describe 'DELETE #destroy' do
        context 'with sufficient permissions' do
          before(:each) do
            set_session_user(@member_user)
            allow(controller).to receive(:call_use_case)
          end

          it 'deletes the object' do
            check_counter_decremented_on_delete(tested_klass, id: create_object.id)
          end

          it 'redirects to repositories#edit' do
            check_delete_status(200, id: create_object.id)
          end
        end

        context 'with unsufficient permissions' do
          it 'renders 403' do
            set_session_user(@anonymous_user)
            check_delete_status(403, id: create_object.id)
          end
        end
      end unless respond_to?(:skip_actions) && skip_actions.include?('destroy')
    end
  end
end
