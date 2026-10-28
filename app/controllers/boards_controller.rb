class BoardsController < ApplicationController
  allow_unauthenticated_access
  layout "board"

  def show
    @board = Board.new(params[:event_id] ? Event.find(params[:event_id]) : Event.current)
    # Any theme can be tried out on the board, as the admin's theme previews do
    @preview_theme = params[:theme].presence_in(Event::THEMES.keys)
    @theme = @preview_theme || @board.theme
  end
end
