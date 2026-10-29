# Below are the routes for madmin
namespace :madmin do
  # The tap list
  resources :events do
    # The board's themes, previewed for the event, and picking one
    member do
      get :themes
      patch :theme
      # Starting its serving session from its list, adding the session the first time
      post :serve
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
  resources :sessions do
    # The start and stop buttons
    member do
      patch :start
      patch :stop
    end
  end
  # A session's settings, which the list's buttons nudge
  resources :settings do
    patch :nudge, on: :member
  end
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
