module BootstrapKit::PresenterHelper
  def present(object, klass = nil, *args)
    klass ||= "#{object.class.base_class}Presenter".constantize
    presenter = klass.new(object, self, *args)
    yield presenter if block_given?
    presenter
  end
end
