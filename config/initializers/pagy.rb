# frozen_string_literal: true

require "pagy"

pagy_config = defined?(Pagy::OPTIONS) ? Pagy::OPTIONS : Pagy::DEFAULT

# Pagy >= 43 freezes DEFAULT and uses OPTIONS for config.
unless pagy_config.frozen?
  pagy_config[:limit] = 50

  begin
    require "pagy/extras/overflow"
    pagy_config[:overflow] = :last_page
  rescue LoadError
    # Pagy >= 43 removed the overflow extra and the :overflow variable.
    pagy_config[:raise_range_error] = false
  end
end
