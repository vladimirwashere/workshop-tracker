# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update deactivate reactivate soft_delete reset_password]

  def index
    authorize User
    scope = policy_scope(User).includes(:user_setting).kept
    if params[:search].present?
      q = "%#{User.sanitize_sql_like(params[:search])}%"
      scope = scope.where("display_name ILIKE :q", q: q)
    end
    scope = scope.order(created_at: :desc)
    @pagy, @users = paginate_or_load_all(scope)
  end

  def show
    authorize @user
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      @user.generate_confirmation_token!
      redirect_to users_path, notice: t("users.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    update_params = user_params.except(:password, :password_confirmation)

    if update_params[:role].present? && @user == Current.user
      update_params = update_params.except(:role)
    end

    if @user.update(update_params)
      @user.sessions.destroy_all if @user.saved_change_to_role?
      redirect_to users_path, notice: t("users.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def deactivate
    authorize @user
    if @user.update(active: false)
      @user.sessions.destroy_all
      redirect_to users_path, notice: t("users.deactivated")
    else
      redirect_to users_path, alert: @user.errors.full_messages.join(", ")
    end
  end

  def reactivate
    authorize @user
    if @user.update(active: true)
      redirect_to users_path, notice: t("users.reactivated")
    else
      redirect_to users_path, alert: @user.errors.full_messages.join(", ")
    end
  end

  def soft_delete
    authorize @user, :destroy?
    @user.discard
    redirect_to users_path, notice: t("users.deleted")
  end

  def reset_password
    authorize @user
    temp_password = "#{SecureRandom.alphanumeric(8).downcase}A1#{SecureRandom.alphanumeric(2)}"
    if @user.update(password: temp_password, password_confirmation: temp_password)
      @user.sessions.destroy_all
      flash[:temp_password] = temp_password
      redirect_to users_path, notice: t("users.password_reset")
    else
      redirect_to users_path, alert: @user.errors.full_messages.join(", ")
    end
  end

  private

  def set_user
    @user = User.kept.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:display_name, :email_address, :password, :password_confirmation, :role)
  end
end
