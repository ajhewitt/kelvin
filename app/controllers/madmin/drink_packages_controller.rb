module Madmin
  # An event's list laid out like the board, with what's needed on the night: kicking drinks,
  # reordering them, adding and removing them
  class DrinkPackagesController < Madmin::ApplicationController
    before_action :set_event, except: :current
    before_action :set_item, except: [:current, :index, :create]

    helper BoardsHelper, SettingsHelper
    helper_method :drink_choices, :package_choices

    def current
      event = Event.current
      redirect_to event ? madmin_event_drink_packages_path(event) : new_madmin_event_path
    end

    def index
      @item = @event.drink_packages.new(params.permit(:drink_id, :package_id))
    end

    def create
      @item = @event.drink_packages.new(params.expect(drink_package: [:drink_id, :package_id, :emoji, :show_image]))

      if @item.save
        redirect_to list_path
      else
        render :index, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @item.update(params.expect(drink_package: [:emoji, :show_image, :kicked]))
        redirect_to list_path
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @item.destroy!
      redirect_to list_path, status: :see_other
    end

    def move
      @item.move(direction)
      redirect_to list_path
    end

    def move_brand
      @item.move_brand(direction)
      redirect_to list_path
    end

    private

    def set_event
      @event = Event.find(params[:event_id])
      @board = Board.new(@event)
    end

    def set_item
      @item = @event.drink_packages.find(params[:id])
    end

    def list_path
      madmin_event_drink_packages_path(@event)
    end

    def direction
      (params[:direction] == "up") ? :up : :down
    end

    # Drinks by brand, the house's own first
    def drink_choices
      Drink.includes(:brand).sort_by { |drink| [drink.brand ? 1 : 0, drink.brand&.name.to_s, drink.name] }
        .group_by { |drink| drink.brand&.name || "House" }
        .map { |brand, drinks| [brand, drinks.map { |drink| [drink.to_s, drink.id] }] }
    end

    # Packages by the side of the board they go on
    def package_choices
      {"Draft" => Package.cooperage, "Bottles and cans" => Package.packaged}.map do |side, packages|
        [side, packages.sort_by { |package| [package.type, package.unit, package.volume] }.map { |package| [package.to_s, package.id] }]
      end
    end
  end
end
