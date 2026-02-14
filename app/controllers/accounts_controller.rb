# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :set_user

  def show
    authorize :account, :show?
  end

  def update
    authorize :account, :update?
    if sensitive_change?
      unless @user.authenticate(params[:current_password].to_s)
        flash.now[:alert] = t("accounts.wrong_current_password")
        @editing = true
        render :show, status: :unprocessable_entity
        return
      end
    end

    if @user.update(account_params)
      if @user.saved_change_to_password_digest?
        @user.sessions.where.not(id: Current.session.id).destroy_all
      end
      redirect_to account_path, notice: t("accounts.updated")
    else
      @editing = true
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def account_params
    params.require(:user).permit(:display_name, :email_address, :password, :password_confirmation)
  end

  def sensitive_change?
    user_params = account_params
    email_changed = user_params[:email_address].present? && user_params[:email_address] != @user.email_address
    password_changed = user_params[:password].present?
    email_changed || password_changed
  end
end
