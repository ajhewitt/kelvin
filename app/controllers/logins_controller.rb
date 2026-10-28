class LoginsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to login_path, alert: "Too many tries. Wait a few minutes and try again." }

  def new
    redirect_to madmin_root_path if current_user
  end

  def create
    if (user = User.authenticate_by(username: params[:username].to_s, password: params[:password].to_s))
      redirect_to log_in(user) || madmin_root_path
    else
      flash.now[:alert] = "Wrong username or password."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    log_out
    redirect_to login_path, notice: "Logged out."
  end
end
