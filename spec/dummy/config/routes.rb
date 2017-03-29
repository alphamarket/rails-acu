Rails.application.routes.draw do

  root to: 'home#index'

  get 'home/contact'

  resources :comments
  resources :books

  mount Acu::Engine => "/acu"
end
