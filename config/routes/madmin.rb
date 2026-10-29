# Below are the routes for madmin
namespace :madmin do
  # The tap list
  resources :events do
    # The board's themes, previewed for the event, and picking one
    member do
      get :themes
      patch :theme
    end
    # Starting its serving from its list the first time, adding its serving session
    resource :serving, only: :create

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
    # Its start and stop buttons and its settings' down and up buttons, on its page and its event's list
    member do
      patch :start
      patch :stop
      patch :nudge
    end
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
