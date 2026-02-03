# frozen_string_literal: true

require 'rails_helper'

# Create a test controller to test ApplicationController methods
class TestApplicationController < ApplicationController
  def test_ensure_admin
    ensure_admin and return
    render plain: 'success'
  end

  def test_ensure_super_admin
    ensure_super_admin and return
    render plain: 'success'
  end
end

RSpec.describe ApplicationController, type: :controller do
  controller(TestApplicationController) do
    def index
      render plain: 'success'
    end
  end

  before do
    routes.draw do
      get 'index' => 'test_application#index'
      get 'test_ensure_admin' => 'test_application#test_ensure_admin'
      get 'test_ensure_super_admin' => 'test_application#test_ensure_super_admin'
    end
  end

  describe '#ensure_admin' do
    context 'when user is admin' do
      let(:admin_user) { create(:user, :officer) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      end

      it 'allows access' do
        get :test_ensure_admin
        expect(response.body).to eq('success')
      end
    end

    context 'when user is not admin' do
      let(:regular_user) { create(:user) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(regular_user)
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      end

      it 'redirects to root path' do
        get :test_ensure_admin
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#ensure_super_admin' do
    context 'when user is super admin' do
      let(:super_admin_user) { create(:user, :super_admin) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(super_admin_user)
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      end

      it 'allows access' do
        get :test_ensure_super_admin
        expect(response.body).to eq('success')
      end
    end

    context 'when user is not super admin' do
      let(:admin_user) { create(:user, :officer) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      end

      it 'redirects to root path' do
        get :test_ensure_super_admin
        expect(response).to redirect_to(root_path)
      end
    end
  end
end

