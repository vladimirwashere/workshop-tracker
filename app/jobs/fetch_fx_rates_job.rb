# frozen_string_literal: true

class FetchFXRatesJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    result = FXFetcher.new.fetch_and_store(date: date)

    unless result.success?
      raise "FX fetch failed for #{date}: #{result.error}"
    end
  end
end
