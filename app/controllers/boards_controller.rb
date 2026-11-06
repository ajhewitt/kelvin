class BoardsController < ApplicationController
  allow_unauthenticated_access
  layout "board"

  def show
    @board = Board.new(params[:event_id] ? Event.find(params[:event_id]) : Event.current)
    # Any theme can be tried out on the board, easter eggs too, as the admin's theme previews do
    @preview_theme = params[:theme].presence_in(Event::ALL_THEMES.keys)
    @theme = @preview_theme || @board.theme
    # The kiosk shows the board in a frame on a page of its own, which reloads it (see kiosk/index.html). That page is
    # opened from the Pi's disk, so it needs the board to allow framing by another origin. Nothing on the board can be
    # clicked, so there's nothing for a framing page to trick anyone into
    @kiosk = params.key?(:kiosk)
    response.headers.delete("X-Frame-Options") if @kiosk
  end
end
