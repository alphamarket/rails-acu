Rails.application.routes.draw do

  namespace :admin do
    get 'manage/index'
    get 'manage/show'
    get 'manage/list'
    get 'manage/delete'
    get 'manage/add'
    get 'manage/prove'
  end

  devise_for :users

  root to: 'home#index'

  get 'home/contact'

  mount Acu::Engine => "/acu"
end
