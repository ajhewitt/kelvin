module Madmin
  class ControlActionsController < Madmin::ResourceController
    private

    def scoped_resources
      super.includes(:actuator, session: :configuration)
    end
  end
end
