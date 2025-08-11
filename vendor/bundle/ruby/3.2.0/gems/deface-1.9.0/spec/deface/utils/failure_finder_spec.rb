require 'spec_helper'
require 'deface/utils/failure_finder'

require 'active_support/testing/stream' if Rails::VERSION::MAJOR >= 5

module Deface
  module Utils
    describe FailureFinder do
      include Deface::Utils::FailureFinder
      include Deface::TemplateHelper
      include ActiveSupport::Testing::Stream if Rails::VERSION::MAJOR >= 5
      include_context "mock Rails.application"

      before do
        #stub view paths to be local spec/assets directory
        allow(ActionController::Base).to receive(:view_paths).and_return([File.join(File.dirname(__FILE__), '../..', "assets")])
      end

      context "given failing overrides" do
        before do
          Deface::Override.new(:virtual_path => "shared/_post", :name => "good", :remove => "p")
          Deface::Override.new(:virtual_path => "shared/_post", :name => "bad", :remove => "img")
        end

        context "overrides_by_virtual_path" do
          it "should load template and apply overrides" do
            fails = overrides_by_virtual_path('shared/_post')
            count = fails.group_by{ |o| !o.failure.nil? }

            expect(count[true].size).to eq 1
            expect(count[true].first.name).to eq 'bad'
            expect(count[false].size).to eq 1
            expect(count[false].first.name).to eq 'good'
          end

          it "should return nil for path virtual_path value" do
            silence_stream(STDOUT) do
              expect(overrides_by_virtual_path('shared/_poster')).to be_nil
            end
          end
        end

        context "output_results_by_virtual_path" do
          it "should return count of failed overrides for given path" do
            silence_stream(STDOUT) do
              expect(output_results_by_virtual_path('shared/_post')).to eq 1
            end
          end
        end
      end

      context "given no failing overrides" do
        before do
          Deface::Override.new(:virtual_path => "shared/_post", :name => "good", :remove => "p")
        end

        context "overrides_by_virtual_path" do
          it "should load template and apply overrides" do
            fails = overrides_by_virtual_path('shared/_post')
            count = fails.group_by{ |o| !o.failure.nil? }

            expect(count.key?('true')).to be_falsy
            expect(count[false].size).to eq 1
            expect(count[false].first.name).to eq 'good'
          end

        end

        context "output_results_by_virtual_path" do
          it "should return count of failed overrides for given path" do
            silence_stream(STDOUT) do
              expect(output_results_by_virtual_path('shared/_post')).to eq 0
            end
          end
        end
      end
    end
  end
end
