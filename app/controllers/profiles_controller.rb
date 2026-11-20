class ProfilesController < ApplicationController
  before_action :require_login

  def update
    if current_user.update(profile_params)
      redirect_back fallback_location: root_path, notice: "Avatar updated successfully!"
    else
      redirect_back fallback_location: root_path, alert: "Could not update avatar."
    end
  end

  private

  def profile_params
    params.require(:user).permit(:avatar_key)
  end
end
