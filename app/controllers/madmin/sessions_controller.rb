module Madmin
  class SessionsController < Madmin::ResourceController
    private

    def scoped_resources
      super.includes(:configuration, :event)
    end
  end
end
