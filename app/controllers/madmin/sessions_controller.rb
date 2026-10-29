module Madmin
  class SessionsController < Madmin::ResourceController
    helper SettingsHelper

    # The start and stop buttons, on a session's page and on its event's list, coming back to the
    # page they were pressed on. They only act at the status they were pressed at, so a double click
    # or a page left open can't stop a session twice and complete it.
    def start
      change_status { @record.start }
    end

    def stop
      change_status { @record.stop }
    end

    # A setting's down and up buttons, a step a press, until the session is complete, as a page left
    # open from before then might not show
    def nudge
      setting = @record.settings.find_by!(key: params[:key])
      if @record.complete?
        flash[:alert] = "#{resource.display_name(@record)} is complete."
      elsif !setting.nudge((params[:direction] == "up") ? :up : :down)
        flash[:alert] = setting.errors.full_messages.to_sentence
      end
      redirect_back_or_to resource.show_path(@record)
    end

    private

    def change_status
      name = resource.display_name(@record)
      if @record.status != params[:from]
        flash[:alert] = "#{name} is already #{@record.status}."
      elsif !yield
        flash[:alert] = @record.errors.full_messages.to_sentence.presence || "#{name} can't do that while #{@record.status}."
      end
      redirect_back_or_to resource.show_path(@record)
    end

    def scoped_resources
      super.includes(:configuration, :event)
    end
  end
end
