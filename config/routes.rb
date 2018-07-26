BetterRecord::Engine.routes.draw do
  root to: 'table_sizes#index'
  resources :table_sizes, only: [ :index, :show ]
end
