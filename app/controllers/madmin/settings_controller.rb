module Madmin
  class SettingsController < Madmin::ResourceController
    # The list's up and down buttons, a step a press
    def nudge
      flash[:alert] = @record.errors.full_messages.to_sentence unless @record.nudge((params[:direction] == "up") ? :up : :down)
      redirect_back_or_to resource.show_path(@record)
    end
  end
end
