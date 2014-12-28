require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersController do

  USER_KEY1   = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZiNOKQtOrBEPGpLC7KZ+dx4zAGEupIWZMuLBbRZJEAjx959b2AcvK5BH1iQ8z6NkBw64MAnXhXY+cwh8HDKg+7ONnf7U+zyWZ/DTuh9DU1k5EQOAq7QXcZWxXgWIhGlNwu4jgxiyilAG0OfLZcNGZO4vP6cMRhdTuvst1PBxR6htQh2EJaeIiW1BsFcB2RR1x5tJIteAJ2NvBolsSPijVmolsX+y1URL3Pt8W8/jlxnscogZpOQHsDZByUBWEiUZNheVCpCsVUM1LkbL0sIIB40B8rKhchlzJYlRCm8axLbbs2lUtSKZBy0Rk1SiERlnGIGuzIda2h1Dbg7vqbMf3 nicolas@tchoum'
  DEPLOY_KEY1 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0B/TiFjjGdLJko8/cZoQyL1Z9BMOjeQfpI45ofq6ROy5jFsfvY8hjBUHnmSFxzRsGLNWK9lWbAhW2WLjPomgcv5RrowJsLFlhVJLAgQ6q4g+4i/PccYcZHXqPLqJLIO1Yxvze7eQvOMtzPt2IYljM4kcR47YnwfbvU40Rq+ezdaIUCaQ4ZjRn879htRKt5SPO6qi8Kgd2s8sUjgJqrFZt9dkzwW+frn5VHgmlO5WT3HrmxF5U6un+uIoiMfX5TjNogn1WQm42vd8Q4f6mAQ9EmK5RK24R24m4YT91Q1b5QBb0qoGap0OJWjmNxX4tvuZ8SSRYXzqLERp7Jcy/r11J nicolas@tchoum'

  def create_ssh_key(opts = {})
    FactoryGirl.create(:gitolite_public_key, opts)
  end

  before(:all) do
    @user = FactoryGirl.create(:user, :admin => true)
    User.current = @user
    @user_key   = create_ssh_key(:user_id => @user.id, :title => 'user_key',   key: USER_KEY1, :key_type => 0)
    @deploy_key = create_ssh_key(:user_id => @user.id, :title => 'deploy_key', key: DEPLOY_KEY1, :key_type => 1)
  end


  describe "GET #edit" do
    context "with git hosting patch" do
      before do
        request.session[:user_id] = @user.id
        get :edit, :id => @user.id
      end

      it "populates an array of gitolite_user_keys" do
        expect(assigns(:gitolite_user_keys)).to eq [@user_key]
      end

      it "populates an array of gitolite_deploy_keys" do
        expect(assigns(:gitolite_deploy_keys)).to eq [@deploy_key]
      end

      it "populates an empty gitolite_public_key" do
        expect(assigns(:gitolite_public_key)).to be_an_instance_of(GitolitePublicKey)
      end
    end
  end

end
