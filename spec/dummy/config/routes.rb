Rails.application.routes.draw do

  devise_for :users

  root to: 'home#index'

  get 'home/contact'

  resources :comments
  resources :books

  mount Acu::Engine => "/acu", :as => "acu"
end
