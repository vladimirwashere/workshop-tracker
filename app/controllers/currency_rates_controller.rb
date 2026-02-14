# frozen_string_literal: true

class CurrencyRatesController < ApplicationController
  def index
    authorize :currency_rate, :index?
    scope = policy_scope(CurrencyRate).order(date: :desc)
    @pagy, @currency_rates = paginate_or_load_all(scope)
    @latest_rate = CurrencyRate.ron_to_gbp.order(date: :desc).first
  end

  def fetch_latest
    authorize :currency_rate, :fetch_latest?

    result = FXFetcher.new.fetch_and_store(date: Date.current)

    if result.success?
      redirect_to currency_rates_path, notice: t("currency_rates.fetch_success", rate: result.rate)
    else
      redirect_to currency_rates_path, alert: t("currency_rates.fetch_failed", error: result.error)
    end
  end
end
