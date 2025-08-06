class Api::V1::AdminController < ApplicationController
  # TEMPORAL: Solo para debugging, eliminar después
  def delete_user
    email = params[:email]
    user = User.find_by(email: email)
    
    if user
      user.destroy
      render json: { message: "User #{email} deleted successfully" }
    else
      render json: { error: "User not found" }, status: 404
    end
  end
  
  def list_users
    users = User.all.select(:id, :email, :name, :created_at)
    render json: users
  end
end