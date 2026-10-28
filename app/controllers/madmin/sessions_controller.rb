module Madmin
  class SessionsController < Madmin::ResourceController
    private

    def scoped_resources
      super.includes(:configuration)
    end
  end
end
