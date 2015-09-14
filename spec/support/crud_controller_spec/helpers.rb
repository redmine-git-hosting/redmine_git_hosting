module CrudControllerSpec
  module Helpers

    ##### INDEX

    def check_index_variable(variable, value)
      get :index, base_options
      check_variable(variable, value)
    end


    def check_index_template
      get :index, base_options
      check_template(:index)
    end


    def check_index_status(status)
      get :index, base_options
      check_status(status)
    end


    ##### SHOW

    def check_api_response(status, opts = {})
      get :show, merge_options(opts).merge(format: 'json')
      check_status(status)
    end


    ##### NEW

    def check_new_variable(variable, klass)
      get :new, base_options
      check_klass(variable, klass)
    end


    def check_new_template
      get :new, base_options
      check_template(:new)
    end


    def check_new_status(status)
      get :new, base_options
      check_status(status)
    end


    ##### CREATE

    def check_create_template(template, opts = {})
      xhr_post merge_options(opts)
      check_template(:create)
    end


    def check_create_status(status, opts = {})
      xhr_post merge_options(opts)
      check_status(status)
    end


    def check_counter_incremented_on_create(klass, opts = {})
      expect { xhr_post merge_options(opts) }.to change(klass, :count).by(1)
    end


    def check_counter_not_changed_on_create(klass, opts = {})
      expect { xhr_post merge_options(opts) }.to_not change(klass, :count)
    end


    ##### EDIT

    def check_edit_variable(variable, value, opts = {})
      get :edit, merge_options(opts)
      check_variable(variable, value)
    end


    def check_edit_template(opts = {})
      get :edit, merge_options(opts)
      check_template(:edit)
    end


    def check_edit_status(status, opts = {})
      get :edit, merge_options(opts)
      check_status(status)
    end


    ##### UPDATE

    def check_update_variable(variable, value, opts = {})
      xhr_put merge_options(opts)
      @object.reload
      check_variable(variable, value)
    end


    def check_attribute_has_changed(method, value, opts = {})
      xhr_put merge_options(opts)
      @object.reload
      check_equality(@object.send(method), value)
    end


    def check_attribute_has_not_changed(method, opts = {})
      old_value = @object.send(method)
      xhr_put merge_options(opts)
      @object.reload
      check_equality(@object.send(method), old_value)
    end


    def check_update_template(opts = {})
      xhr_put merge_options(opts)
      check_template(:update)
    end


    def check_update_status(status, opts = {})
      xhr_put merge_options(opts)
      check_status(status)
    end


    ##### DELETE

    def check_counter_decremented_on_delete(klass, opts = {})
      expect { delete :destroy, merge_options(opts).merge(format: 'js') }.to change(klass, :count).by(-1)
    end


    def check_delete_status(status, opts = {})
      delete :destroy, merge_options(opts).merge(format: 'js')
      check_status(status)
    end


    private


      def base_options
        { repository_id: @repository.id }.clone
      end


      def merge_options(opts = {})
        base_options.merge(opts)
      end


      def member_user_options
        { permissions: permissions }
      end


      def check_klass(variable, klass)
        expect(assigns(variable)).to be_an_instance_of(klass)
      end


      def check_variable(variable, value)
        expect(assigns(variable)).to eq value
      end


      def check_template(template)
        expect(response).to render_template(template)
      end


      def check_status(status)
        expect(response.status).to eq status
      end


      def check_equality(variable, value)
        expect(variable).to eq value
      end


      def xhr_post(opts = {})
        xhr :post, :create, opts
      end


      def xhr_put(opts = {})
        xhr :put, :update, opts
      end

  end
end
