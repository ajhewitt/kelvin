module Madmin
  class UsersController < Madmin::ResourceController
    def update
      super
      # A new password ends the user's logins, so this one starts again
      log_in(@record) if @record == current_user && @record.saved_change_to_password_digest?
    end

    def destroy
      return destroy_failed("You can't delete yourself") if @record == current_user

      super
    end
  end
end
