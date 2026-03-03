# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('/public/home')
  
  # Public Pages Namespace
  namespace :public, path: 'public' do
    get 'home', to: 'pages#home'
    get 'performance_request', to: 'pages#performance_request'
    get 'media_gallery', to: 'pages#media_gallery'
    get 'audition_information', to: 'pages#audition_information'
    get 'calendar', to: 'pages#calendar'
    get 'contact', to: 'pages#contact'
  end

  # Manual authentication routes (using custom controller to avoid Devise mapping issues)
  get '/users/sign_in', to: 'auth#sign_in'
  post '/users/sign_in', to: 'auth#create'
  delete '/users/sign_out', to: 'auth#destroy'

  # Alternative paths for cleaner URLs
  get '/auth/sign_in', to: 'auth#sign_in'
  post '/auth/sign_in', to: 'auth#create'
  delete '/auth/sign_out', to: 'auth#destroy'

  # OAuth routes - manual handling since middleware might not be working
  get '/auth/google_oauth2', to: 'auth#oauth_redirect'
  get '/auth/google_oauth2/callback', to: 'users/omniauth_callbacks#google_oauth2'

  # Redirect old paths to new ones
  get '/users/auth/google_oauth2', to: redirect('/auth/google_oauth2')
  get '/users/auth/google_oauth2/callback', to: redirect('/auth/google_oauth2/callback')

  # Devise routes for users (backup - may not work until DB is migrated)
  begin
    devise_for :users, controllers: {
      omniauth_callbacks: 'users/omniauth_callbacks',
      sessions: 'users/sessions',
    }, skip: [:registrations]
  rescue StandardError => e
    Rails.logger.warn "Devise routes not loaded: #{e.message}"
  end

  # Internal Member Routes
  namespace :internal, path: 'internal' do
    resources :users, path: 'user_management' do
      member do
        patch :promote_to_officer
        patch :promote_to_super_admin
        patch :demote_to_user
        patch :demote_to_officer
        get :attendance_history
      end
      
      collection do
        get :absence_report
      end
    end

    resources :events do
      resources :attendances, only: %i[new create update]
      member do
        get :self_checkin, to: 'attendances#self_checkin_form'
        post :self_checkin, to: 'attendances#self_checkin'
      end
    end

    resources :excuses, only: [:index, :show, :new, :create, :update] do
      member do
        post :review
        post :cancel_recurring
      end
    end
    
    resources :demerits

    # Allows Director to Manage Dynamic Sections (Tenor 1, Tenor 2, etc.)
    resources :sections, only: [:index, :create, :destroy]
    
    # Special route for creating demerits for a specific member
    get '/users/:member_id/demerits/new', to: 'demerits#new', as: 'new_member_demerit'
    
    # Member-specific routes
    get '/my-demerits', to: 'members#my_demerits', as: 'my_demerits'
    get '/help', to: 'help#show', as: 'help'
  end

  # Admin routes
  namespace :admin do
    resources :registrations, only: [:index] do
      member do
        patch :approve
        patch :reject
        delete :destroy_rejected
      end
    end
  end
end
