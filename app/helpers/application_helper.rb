# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Formatting

  def format_date(date)
    return "" unless date

    I18n.l(date, format: :default)
  end

  def format_number(number, precision: 2)
    return "" unless number

    number_with_precision(number, precision: precision)
  end

  def format_currency(amount, currency: nil, date: nil)
    return "" unless amount

    if currency.present?
      return "#{number_with_precision(amount, precision: 2)} #{currency}"
    end

    ron_str = "#{number_with_precision(amount, precision: 2)} RON"
    return ron_str if current_currency == "RON"

    gbp_value = CurrencyConverter.convert(amount, currency: "GBP")

    if gbp_value.nil?
      content_tag(:span, class: "inline-flex items-center gap-1") do
        concat(ron_str)
        concat(" ")
        concat(content_tag(:span, t("currency_rates.missing_fx_short"),
          class: "text-xs px-1.5 py-0.5 bg-amber-100 text-amber-800 rounded-lg",
          title: t("currency_rates.missing_fx_detail")))
      end
    else
      "#{number_with_precision(gbp_value, precision: 2)} GBP"
    end
  end

  # Badges

  STATUS_COLORS = {
    "planned"     => "bg-slate-100/80 text-slate-700 border border-slate-200/50",
    "active"      => "bg-gradient-to-r from-blue-500/20 to-cyan-500/20 text-blue-800 border border-blue-300/30 backdrop-blur-sm",
    "in_progress" => "bg-gradient-to-r from-yellow-500/20 to-amber-500/20 text-yellow-800 border border-yellow-300/30 backdrop-blur-sm",
    "completed"   => "bg-gradient-to-r from-green-500/20 to-emerald-500/20 text-green-800 border border-green-300/30 backdrop-blur-sm",
    "done"        => "bg-gradient-to-r from-green-500/20 to-emerald-500/20 text-green-800 border border-green-300/30 backdrop-blur-sm",
    "on_hold"     => "bg-gradient-to-r from-yellow-500/20 to-amber-500/20 text-orange-800 border border-yellow-300/30 backdrop-blur-sm",
    "cancelled"   => "bg-gradient-to-r from-red-500/20 to-rose-500/20 text-red-800 border border-red-300/30 backdrop-blur-sm"
  }.freeze

  PRIORITY_COLORS = {
    "low"    => "bg-slate-100/80 text-slate-600 border border-slate-200/50",
    "medium" => "bg-gradient-to-r from-yellow-500/20 to-amber-500/20 text-yellow-700 border border-yellow-300/30 backdrop-blur-sm",
    "high"   => "bg-gradient-to-r from-red-500/20 to-rose-500/20 text-red-700 border border-red-300/30 backdrop-blur-sm"
  }.freeze

  def badge(value, color_map, default_class: "bg-slate-100/80 text-slate-700 border border-slate-200/50")
    color_class = color_map[value.to_s] || default_class
    content_tag(:span, value.to_s.titleize, class: "badge #{color_class}")
  end

  def status_badge(status)
    badge(status, STATUS_COLORS)
  end

  def priority_badge(priority)
    badge(priority, PRIORITY_COLORS, default_class: "bg-slate-100/80 text-slate-600 border border-slate-200/50")
  end

  def active_badge(active)
    if active
      badge(t("common.yes"), { t("common.yes") => "bg-gradient-to-r from-green-500/20 to-emerald-500/20 text-green-800 border border-green-300/30" })
    else
      badge(t("common.no"), { t("common.no") => "bg-gradient-to-r from-red-500/20 to-rose-500/20 text-red-800 border border-red-300/30" })
    end
  end

  # Authorization — single source of truth for view-layer permission checks
  def can_manage?
    Current.user&.admin? || Current.user&.manager?
  end

  def can_view_costs?
    Current.user&.admin? || Current.user&.owner? || Current.user&.manager?
  end

  # Period filter

  def active_period(date_from, date_to)
    return nil unless date_from.present? && date_to.present?

    date_from = date_from.to_date if date_from.respond_to?(:to_date)
    date_to = date_to.to_date if date_to.respond_to?(:to_date)

    if matches_this_week?(date_from, date_to)
      :this_week
    elsif matches_this_month?(date_from, date_to)
      :this_month
    elsif matches_this_year?(date_from, date_to)
      :this_year
    end
  end

  def period_button_classes(active)
    if active
      "bg-indigo-100/80 border-indigo-500 text-indigo-700 font-medium shadow-sm"
    else
      "border-slate-300 hover:bg-slate-50 text-slate-600 hover:border-slate-400"
    end
  end

  def report_type_classes(selected)
    if selected
      "bg-indigo-100/80 border-indigo-500 shadow-sm"
    else
      "border-slate-200 hover:bg-slate-50/80 hover:border-slate-300"
    end
  end

  def dropdown_all_selected_classes(all_selected)
    base = "select-premium"
    all_selected ? "#{base} border-indigo-500 bg-indigo-50/80" : base
  end

  # Sidebar navigation

  def sidebar_nav_item(path:, label:, icon:, active: nil)
    is_active = active.nil? ? request.path.start_with?(path) : active
    css = is_active ? "sidebar-link-active" : "sidebar-link-inactive"
    link_to path, class: css do
      concat(content_tag(:span, icon.html_safe, class: "sidebar-icon"))
      concat(content_tag(:span, label))
    end
  end

  private

  def matches_this_week?(date_from, date_to)
    date_from == Date.current.beginning_of_week(:monday) && date_to == Date.current.end_of_week(:sunday)
  end

  def matches_this_month?(date_from, date_to)
    date_from == Date.current.beginning_of_month && date_to == Date.current.end_of_month
  end

  def matches_this_year?(date_from, date_to)
    date_from == Date.current.beginning_of_year && date_to == Date.current.end_of_year
  end
end
