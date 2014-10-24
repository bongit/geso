Rails.application.routes.draw do
  root 'static_pages#top'
  resources :game_assets do
    member do
      get :download
      get :add_to_cart
      get :get_free_asset
      get :review_new
      get :review_edit
      match 'thumbnail', to: 'game_assets#thumbnail_check', via: 'post'
      match 'screenshot', to: 'game_assets#screenshot_check', via: 'post'
      get :asset_file_upload
      match 'asset_file_upload', to: 'game_assets#zip', via: 'post'
      get :asset_file_confirm
      match 'asset_file_confirm', to: 'game_assets#upload', via: 'post'
    end
  end
  resources :users do
    member do
      get :bought_assets
      get :cart
      match 'cart', to: 'users#cart_delete', via: 'patch'
      match 'cart', to: 'users#cart_delete_all', via: 'delete'
      match 'cart', to: 'users#order', via: 'post'
      get :order_complete
      get :cancel
      get :following, :followers
      get :edit_new_password
      match 'edit_new_password', to: 'users#update_password', via: 'patch'
    end
    collection do
      get :forgot_password
      match 'forgot_password', to: 'users#send_password_reset', via: 'post'
    end
  end
  resources :reviews, only:[:create, :update, :destroy]
  resources :relationships, only: [:create, :destroy]
  resources :sessions, only: [:new, :create, :destroy]
  match '/signup',  to: 'users#new',            via: 'get'
  match '/signin',  to: 'sessions#new',         via: 'get'
  match '/signout', to: 'sessions#destroy',     via: 'delete'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
