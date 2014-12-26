require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Hooks::GitMirrors do

  # describe "Push args" do
  #   ## Validate push args : forced mode
  #   context "when push_mode forced with params" do
  #     before do
  #       @mirror = build_mirror(:url => MIRROR_URL, :push_mode => 1, :explicit_refspec => 'devel')
  #     end

  #     it "should have push_args" do
  #       expect(@mirror.push_args).to eq ["--force", MIRROR_URL, "devel"]
  #     end
  #   end

  #   ## Validate push args : fast_forward mode
  #   context "when push_mode fast_forward with params" do
  #     before do
  #       @mirror = build_mirror(:url => MIRROR_URL, :push_mode => 2, :explicit_refspec => 'devel')
  #     end

  #     it "should have push_args" do
  #       expect(@mirror.push_args).to eq [MIRROR_URL, "devel"]
  #     end
  #   end

  #   ## Validate push args : mirror mode
  #   context "when push_mode is mirror" do
  #     before do
  #       @mirror = build_mirror(:url => MIRROR_URL, :push_mode => 0)
  #     end

  #     it "should have push_args" do
  #       expect(@mirror.push_args).to eq ["--mirror", MIRROR_URL]
  #     end
  #   end

  #   ## Validate push args : all tags mode
  #   context "when push_mode is all tags" do
  #     before do
  #       @mirror = build_mirror(:url => MIRROR_URL, :push_mode => 1, :include_all_tags => true)
  #     end

  #     it "should have push_args" do
  #       expect(@mirror.push_args).to eq ["--force", "--tags", MIRROR_URL]
  #     end
  #   end

  #   ## Validate push args : all branches mode
  #   context "when push_mode is all branches" do
  #     before do
  #       @mirror = build_mirror(:url => MIRROR_URL, :push_mode => 1, :include_all_branches => true)
  #     end

  #     it "should have push_args" do
  #       expect(@mirror.push_args).to eq ["--force", "--all", MIRROR_URL]
  #     end
  #   end
  # end

end
