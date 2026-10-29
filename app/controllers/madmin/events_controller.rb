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

    # Starts serving from the event's page the first time, with a new serving session, created
    # pending and then started. After that the page has the session's own start and stop buttons.
    def serve
      if @record.serving_session
        flash[:alert] = "#{@record.name} already has a serving session."
      else
        serving = @record.build_serving_session(configuration: Configuration.serving)
        flash[:alert] = serving.errors.full_messages.to_sentence unless serving.save && serving.start
      end
      redirect_to resource.show_path(@record)
    end
  end
end
