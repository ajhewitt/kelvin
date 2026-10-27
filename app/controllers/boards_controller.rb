class BoardsController < ApplicationController
  layout "board"

  def show
    @board = Board.new(params[:event_id] ? Event.find(params[:event_id]) : Event.current)
  end
end
