module Madmin
  class ApplicationController < Madmin::BaseController
    # The app's own routes, like Madmin's version of this controller
    include Rails.application.routes.url_helpers
    include Authentication
  end
end
