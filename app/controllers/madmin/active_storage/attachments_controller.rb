module Madmin
  class ActiveStorage::AttachmentsController < Madmin::ResourceController
    # Removing a drink's image goes back to its form rather than a list of attachments
    def destroy
      @record.destroy
      redirect_back_or_to madmin_root_path, status: :see_other
    end
  end
end
