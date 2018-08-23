# frozen_string_literal: true

BetterRecord::Engine.routes.draw do
  root to: 'table_sizes#index'

  resources :table_sizes, only: %i[ index show ]

  namespace :api do
    resources :sessions, only: %i[ new create destroy ]
    get :sessions, to: 'sessions#new'
  end
end
