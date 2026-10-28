# Logging in to the admin screens. Every page needs a login unless its controller allows
# unauthenticated access, as the board on the TV does.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_login
    helper_method :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_login, **options
    end
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:login] && User.find_by_token_for(:login, session[:login])
  end

  def require_login
    return if current_user

    # Only pages can be gone back to after logging in
    session[:return_to] = request.fullpath if request.get? || request.head?
    redirect_to main_app.login_path
  end

  # Starts a fresh session for the user, returning the page they were sent to log in from
  def log_in(user)
    return_to = session[:return_to]
    reset_session
    session[:login] = user.generate_token_for(:login)
    @current_user = user
    return_to
  end

  def log_out
    reset_session
  end
end
