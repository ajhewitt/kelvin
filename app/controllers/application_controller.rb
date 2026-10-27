class ApplicationController < ActionController::Base
  # No allow_browser check: the kiosk's WPE WebKit reports itself as Safari 17.0 or older
  # before WPE 2.46, which Rails' :modern preset would turn away with a 406.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
