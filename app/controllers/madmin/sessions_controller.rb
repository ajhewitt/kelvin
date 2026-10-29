module Madmin
  class SessionsController < Madmin::ResourceController
    # The start and stop buttons, which only act at the status they were pressed at, so a double
    # click or a page left open can't stop a session twice and complete it
    def start
      change_status { @record.start }
    end

    def stop
      change_status { @record.stop }
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
