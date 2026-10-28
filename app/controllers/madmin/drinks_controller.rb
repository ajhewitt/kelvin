module Madmin
  class DrinksController < Madmin::ResourceController
    # A new brew starts as a copy, image and all, so the drink's earlier events keep their numbers
    def copy
      copy = @record.dup
      copy.image.attach(@record.image.blob) if @record.image.attached?
      copy.save!

      redirect_to resource.edit_path(copy), notice: "Copied #{@record.name}. Update the numbers for the new brew."
    end

    private

    def scoped_resources
      super.includes(:brand)
    end
  end
end
