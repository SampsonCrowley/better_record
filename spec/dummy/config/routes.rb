Rails.application.routes.draw do
  mount BetterRecord::Engine => "/"
  root to: 'better_record/table_sizes#index'
end
