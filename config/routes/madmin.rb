# Below are the routes for madmin
namespace :madmin do
  resources :events do
    # The board's themes, previewed for the event, and picking one
    member do
      get :themes
      patch :theme
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
  resources :users
  namespace :active_storage do
    # Removing a drink's image from its form
    resources :attachments, only: :destroy
  end

  # The admin opens on the list for the event the board is showing
  root to: "drink_packages#current"
end
