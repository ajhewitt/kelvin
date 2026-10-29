module Madmin
  # An event's serving session, run from the event's list: started, stopped, and its draft
  # temperature turned up and down. Each button comes back to the list.
  class ServingsController < Madmin::ApplicationController
    before_action :set_event
    before_action :set_serving, except: :create

    # Starts serving the first time, with a new serving session, created pending and then started
    def create
      if @event.serving_session
        flash[:alert] = "#{@event.name} already has a serving session."
      else
        serving = @event.build_serving_session(configuration: Configuration.serving)
        flash[:alert] = serving.errors.full_messages.to_sentence unless serving.save && serving.start
      end
      redirect_to list_path
    end

    # Start and stop only act at the status they were pressed at, so a double click or a page left
    # open can't stop the session twice and complete it
    def start
      change_status { @serving.start }
    end

    def stop
      change_status { @serving.stop }
    end

    # A degree warmer or colder a press
    def draft_temp
      setting = @serving.draft_temp or raise ActiveRecord::RecordNotFound
      flash[:alert] = setting.errors.full_messages.to_sentence unless setting.nudge((params[:direction] == "up") ? :up : :down)
      redirect_to list_path
    end

    private

    def set_event
      @event = Event.find(params[:event_id])
    end

    def set_serving
      @serving = @event.serving_session or raise ActiveRecord::RecordNotFound
    end

    def change_status
      if @serving.status != params[:from]
        flash[:alert] = "Serving is already #{@serving.status}."
      elsif !yield
        flash[:alert] = @serving.errors.full_messages.to_sentence.presence || "Serving can't do that while #{@serving.status}."
      end
      redirect_to list_path
    end

    def list_path
      madmin_event_drink_packages_path(@event)
    end
  end
end
