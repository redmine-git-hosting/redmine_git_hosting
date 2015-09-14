require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryPostReceiveUrlsController do

  include CrudControllerSpec::Base


  def permissions
    [:manage_repository, :create_repository_post_receive_urls, :view_repository_post_receive_urls, :edit_repository_post_receive_urls]
  end


  def create_object
    FactoryGirl.create(:repository_post_receive_url, repository_id: @repository.id)
  end


  def success_url
    "/repositories/#{@repository.id}/edit?tab=repository_post_receive_urls"
  end


  def variable_for_index
    :repository_post_receive_urls
  end


  def main_variable
    :post_receive_url
  end


  def tested_klass
    RepositoryPostReceiveUrl
  end


  def valid_params_for_create
    { repository_post_receive_url: { url: "http://#{Faker::Internet.domain_name}", mode: :github } }
  end


  def invalid_params_for_create
    { repository_post_receive_url: { url: Faker::Internet.domain_name, push_mode: 0 } }
  end


  def valid_params_for_update
    { id: @object.id, repository_post_receive_url: { url: 'http://example.com/toto.php' } }
  end


  def updated_attribute
    :url
  end


  def updated_attribute_value
    'http://example.com/toto.php'
  end


  def invalid_params_for_update
    { id: @object.id, repository_post_receive_url: { url: Faker::Internet.domain_name } }
  end

end
