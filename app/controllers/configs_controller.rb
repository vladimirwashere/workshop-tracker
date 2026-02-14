# frozen_string_literal: true

class ConfigsController < ApplicationController
  before_action :set_config, only: %i[edit update]

  def index
    authorize :config, :index?
    @configs = policy_scope(Config).order(:key)
  end

  def edit
    authorize @config, :update?
  end

  def update
    authorize @config, :update?

    if @config.update(config_params)
      redirect_to configs_path, notice: t("configs.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_config
    @config = Config.find(params[:id])
  end

  def config_params
    params.require(:config).permit(:value)
  end
end
