# Below are the routes for madmin
namespace :madmin do
  # The tap list
  resources :events do
    # The board's themes, previewed for the event, and picking one
    member do
      get :themes
      patch :theme
    end
    # Its serving session, run from its list: started (and added, the first time), stopped, and its
    # draft temperature turned up and down
    resource :serving, only: :create do
      patch :start
      patch :stop
      patch :draft_temp
    end

    # An event's list, as it'll show on the board
    resources :drink_packages, path: "list", only: [:index, :create, :edit, :update, :destroy] do
      member do
        patch :move
        patch :move_brand
      end
    end
  end
  resources :drinks do
    post :copy, on: :member
  end
  resources :brands
  resources :packages

  # Refrigeration
  resources :configurations
  resources :sessions
  resources :sensors
  resources :actuators

  # Logs the hardware writes, to look through rather than change
  resources :sensor_readings, only: [:index, :show]
  resources :control_actions, only: [:index, :show]

  resources :users
  namespace :active_storage do
    # Removing a drink's image from its form
    resources :attachments, only: :destroy
  end

  # The admin opens on the list for the event the board is showing
  root to: "drink_packages#current"
end
