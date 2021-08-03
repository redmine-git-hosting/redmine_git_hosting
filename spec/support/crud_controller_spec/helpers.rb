# frozen_string_literal: true

module CrudControllerSpec
  module Helpers
    ##### INDEX
    def check_index_template
      get :index, params: base_options
      assert_response :success
    end

    def check_index_status(status)
      get :index, params: base_options
      check_status status
    end

    ##### SHOW

    def check_api_response(status, **opts)
      get :show, params: merge_options(**opts).merge(format: 'json')
      check_status status
    end

    ##### NEW

    def check_new_variable(_variable, _klass)
      get :new, params: base_options, xhr: true
      assert_response :success
    end

    def check_new_template
      get :new, params: base_options, xhr: true
      assert_response :success
    end

    def check_new_status(status)
      get :new, params: base_options, xhr: true
      check_status status
    end

    ##### CREATE

    def check_create_template(_template, **opts)
      post :create, params: merge_options(**opts), xhr: true
    end

    def check_create_status(status, **opts)
      post :create, params: merge_options(**opts), xhr: true
      check_status status
    end

    def check_counter_incremented_on_create(klass, **opts)
      expect { post :create, params: merge_options(**opts), xhr: true }.to change(klass, :count).by(1)
    end

    def check_counter_not_changed_on_create(klass, **opts)
      expect { post :create, params: merge_options(**opts), xhr: true }.not_to change(klass, :count)
    end

    ##### EDIT

    def check_edit_variable(_variable, _value, **opts)
      get :edit, params: merge_options(**opts), xhr: true
    end

    def check_edit_template(**opts)
      get :edit, params: merge_options(**opts), xhr: true
      assert_response :success
    end

    def check_edit_status(status, **opts)
      get :edit, params: merge_options(**opts), xhr: true
      check_status status
    end

    ##### UPDATE

    def check_update_variable(_variable, _value, **opts)
      put :update, params: merge_options(**opts), xhr: true
      @object.reload
    end

    def check_attribute_has_changed(method, value, **opts)
      put :update, params: merge_options(**opts), xhr: true
      @object.reload
      check_equality(@object.send(method), value)
    end

    def check_attribute_has_not_changed(method, **opts)
      old_value = @object.send method
      put :update, params: merge_options(**opts), xhr: true
      @object.reload
      check_equality(@object.send(method), old_value)
    end

    def check_update_template(**opts)
      put :update, params: merge_options(**opts), xhr: true
    end

    def check_update_status(status, **opts)
      put :update, params: merge_options(**opts), xhr: true
      check_status status
    end

    ##### DELETE

    def check_counter_decremented_on_delete(klass, **opts)
      expect { delete :destroy, params: merge_options(opts).merge(format: 'js') }.to change(klass, :count).by(-1)
    end

    def check_delete_status(status, **opts)
      delete :destroy, params: merge_options(opts).merge(format: 'js')
      check_status status
    end

    private

    def base_options
      { repository_id: @repository.id }.clone
    end

    def merge_options(opts)
      opts ||= {}
      base_options.merge opts
    end

    def member_user_options
      { permissions: permissions }
    end

    def check_status(status)
      expect(response.status).to eq status
    end

    def check_equality(variable, value)
      expect(variable).to eq value
    end
  end
end
