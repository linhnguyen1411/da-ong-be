Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Sitemap for SEO
  get "sitemap.xml", to: "sitemap#index", format: :xml, as: :sitemap

  namespace :api do
    namespace :v1 do
      get 'menu_images/index'
      # Auth
      post 'auth/login', to: 'auth#login'
      get 'auth/me', to: 'auth#me'

      # Health check
      get 'health', to: 'health#index'

      # Public APIs
      resources :categories, only: [:index, :show]
      resources :menu_items, only: [:index, :show]
      resources :best_sellers, only: [:index, :show]
      resources :daily_specials, only: [:index, :show]
      resources :contacts, only: [:create]
      resources :rooms, only: [:index, :show]
      resources :menu_images, only: [:index]
      resources :bookings, only: [:create] do
        collection do
          get :check_availability
        end
      end

      # Zalo webhook
      post 'zalo/webhook', to: 'zalo_webhook#message'
      get 'zalo/webhook', to: 'zalo_webhook#verify'
      get 'zalo/followers', to: 'zalo_webhook#followers'

      # Admin APIs
      namespace :admin do
        get 'menu_images/index'
        get 'menu_images/create'
        get 'menu_images/destroy'
        # File uploads
        resources :uploads, only: [:create, :destroy]

        resources :categories do
          collection do
            post :reorder
          end
        end

        resources :menu_items do
          member do
            post :upload_images
            delete 'delete_image/:image_id', to: 'menu_items#delete_image', as: :delete_image
          end
          collection do
            post :reorder
            get :export
            post :import
          end
        end

        resources :best_sellers do
          member do
            patch :toggle_pin
            patch :toggle_highlight
            post :upload_images
            delete 'delete_image/:image_id', to: 'best_sellers#delete_image', as: :delete_image
          end
          collection do
            post :reorder
          end
        end

        resources :daily_specials do
          member do
            patch :toggle_pin
            patch :toggle_highlight
            post :upload_images
            delete 'delete_image/:image_id', to: 'daily_specials#delete_image', as: :delete_image
          end
        end

        resources :contacts, only: [:index, :show, :destroy] do
          member do
            patch :mark_read
            patch :mark_unread
          end
          collection do
            patch :mark_all_read
            get :stats
          end
        end

        resources :rooms do
          member do
            patch :update_status
            post :upload_images
            delete 'delete_image/:image_id', to: 'rooms#delete_image', as: :delete_image
          end
          collection do
            post :reorder
            get :stats
          end
        end

        resources :bookings, only: [:index, :show, :update, :destroy] do
          member do
            patch :confirm
            patch :cancel
            patch :complete
          end
          collection do
            get :today
            get :upcoming
            get :stats
            get :dashboard
          end
        end

        resources :menu_images do
          collection do
            post :reorder
          end
        end
      end
    end
  end
end
