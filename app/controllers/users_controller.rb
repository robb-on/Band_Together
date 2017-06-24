class UsersController < ApplicationController

  before_action :authenticate_user!

  def show

    if(!params[:id].nil? )
      begin  	 
        @user = User.find(params[:id])
        @createdBands = @user.bands
        @joinedBands = @user.joined_bands
      rescue ActiveRecord::RecordNotFound
        redirect_to "/404"
      end
    else
      redirect_to "/404"
    end
  end

  def index
    search = params[:search].present? ? params[:search] : nil
    @users = if search
      User.search(search)
    else
      User.all
    end       
  end

  def home
    @user = current_user
  end

  #GET
  def edit_profile_informations
    @user = current_user

  end

  def update_profile_informations
    @user = current_user
    updated = @user.update_without_password(user_params)
    if updated
      redirect_to users_home_path
      flash[:success] = "Successfully updated informations."
    else
      render users_edit_profile_informations_path
    #  flash[:danger] = "Invalid parameters : " + user.errors.full_messages
    end
  end



  private

  def user_params
    params.require(:user).permit(:first_name,:last_name,:gender,:birth,:nation,:region, :city, :musical_genre_id, :type_of_musician_id)
  end

end
