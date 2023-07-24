# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :heroku do
    resources :webhooks, only: [:create]
  end
  namespace :segment do
    resources :webhooks, only: [:create]
  end

  resources :events, only: [:index]
  resources :setup, only: [:index]

  get '/ci' => 'setup#ci'

  root to: 'dashboard#index'

  get 'login' => 'sessions#new'
  get 'logout' => 'sessions#logout'
  get '/auth/:provider/callback' => 'sessions#create'
end
