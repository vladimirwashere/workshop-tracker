# frozen_string_literal: true

Pagy::DEFAULT[:limit] = 50

begin
  require "pagy/extras/overflow"
  Pagy::DEFAULT[:overflow] = :last_page
rescue LoadError
  # Pagy >= 43 removed the overflow extra and the :overflow variable.
  Pagy::DEFAULT[:raise_range_error] = false
end
