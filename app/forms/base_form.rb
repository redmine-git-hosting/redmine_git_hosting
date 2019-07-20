module BaseForm
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Conversion
    extend ActiveModel::Naming
  end

  def persisted?
    false
  end

  def submit(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
    if valid?
      valid_form_submitted if respond_to?(:valid_form_submitted)
      true
    else
      false
    end
  end
end
