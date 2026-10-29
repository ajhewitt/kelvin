module Madmin
  # Starts an event's serving from its list the first time, with a new serving session, created
  # pending and then started. After that the list has the session's own start and stop buttons.
  class ServingsController < Madmin::ApplicationController
    def create
      event = Event.find(params[:event_id])
      if event.serving_session
        flash[:alert] = "#{event.name} already has a serving session."
      else
        serving = event.build_serving_session(configuration: Configuration.serving)
        flash[:alert] = serving.errors.full_messages.to_sentence unless serving.save && serving.start
      end
      redirect_to madmin_event_drink_packages_path(event)
    end
  end
end
