module Madmin
  class EventsController < Madmin::ResourceController
    # Every theme, previewed on the event's board
    def themes
    end

    # Picks one of the previewed themes, staying on the previews
    def theme
      if @record.update(theme: params[:theme])
        redirect_to themes_madmin_event_path(@record), notice: "The board now uses #{@record.theme.titleize}."
      else
        redirect_to themes_madmin_event_path(@record), alert: @record.errors.full_messages.to_sentence
      end
    end
  end
end
