module Madmin
  class SensorReadingsController < Madmin::ResourceController
    private

    def scoped_resources
      super.includes(:sensor, session: :configuration)
    end
  end
end
