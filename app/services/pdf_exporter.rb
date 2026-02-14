# frozen_string_literal: true

require "prawn"
require "prawn/table"

class PdfExporter
  FONT_SIZE = 9
  TITLE_SIZE = 14
  HEADER_COLOR = "4B5563"
  HEADER_TEXT = "FFFFFF"

  def self.labour_by_project(data, date_range:, currency: "RON")
    generate_pdf("Labour by Project", date_range) do |pdf|
      data.each do |row|
        pdf.text(row[:project]&.name || "Unknown", size: 11, style: :bold)
        pdf.move_down 4

        table_data = [["Worker", "Days", "Cost (#{currency})"]]
        (row[:workers] || []).each do |w|
          table_data << [
            w[:worker]&.full_name || "Unknown",
            w[:days].to_i.to_s,
            format_number(convert_amount(w[:cost_ron], currency: currency))
          ]
        end
        table_data << [ "Total", row[:total_days].to_i.to_s, format_number(convert_amount(row[:total_cost_ron], currency: currency)) ]

        render_table(pdf, table_data)
        pdf.move_down 12
      end
    end
  end

  def self.labour_summary(data, date_range:, currency: "RON")
    generate_pdf("Labour Summary", date_range) do |pdf|
      table_data = [["Project", "Days", "Cost (#{currency})"]]
      data.each do |row|
        table_data << [
          row[:project]&.name || "Unknown",
          row[:total_days].to_i.to_s,
          format_number(convert_amount(row[:total_cost_ron], currency: currency))
        ]
      end

      render_table(pdf, table_data)
    end
  end

  def self.materials_by_project(data, date_range:, currency: "RON")
    generate_pdf("Materials by Project", date_range) do |pdf|
      data.each do |row|
        pdf.text(row[:project]&.name || "Unknown", size: 11, style: :bold)
        pdf.move_down 4

        table_data = [["Description", "Qty", "Unit", "Ex VAT (#{currency})", "VAT (#{currency})", "Inc VAT (#{currency})"]]
        (row[:entries] || []).each do |e|
          table_data << [
            e.description, e.quantity.to_s, e.unit,
            format_number(convert_amount(e.total_cost_ex_vat_ron, currency: currency)),
            format_number(convert_amount(e.total_vat_ron, currency: currency)),
            format_number(convert_amount(e.total_cost_inc_vat_ron, currency: currency))
          ]
        end
        table_data << [
          "Total", "", "",
          format_number(convert_amount(row[:total_ex_vat_ron], currency: currency)),
          format_number(convert_amount(row[:total_vat_ron], currency: currency)),
          format_number(convert_amount(row[:total_inc_vat_ron], currency: currency))
        ]

        render_table(pdf, table_data)
        pdf.move_down 12
      end
    end
  end

  def self.combined_cost(data, date_range:, currency: "RON")
    generate_pdf("Combined Cost", date_range) do |pdf|
      table_data = [[
        "Project",
        "Labour (#{currency})",
        "Materials Ex VAT (#{currency})",
        "Materials VAT (#{currency})",
        "Materials Inc VAT (#{currency})",
        "Total (#{currency})"
      ]]
      data.each do |row|
        table_data << [
          row[:project]&.name || "Unknown",
          format_number(convert_amount(row[:labour_cost_ron], currency: currency)),
          format_number(convert_amount(row[:materials_ex_vat_ron], currency: currency)),
          format_number(convert_amount(row[:materials_vat_ron], currency: currency)),
          format_number(convert_amount(row[:materials_inc_vat_ron], currency: currency)),
          format_number(convert_amount(row[:total_ron], currency: currency))
        ]
      end

      render_table(pdf, table_data)
    end
  end

  class << self
    private

    def generate_pdf(title, date_range)
      pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: 30)
      pdf.text title, size: TITLE_SIZE, style: :bold
      pdf.text "Period: #{date_range.first} - #{date_range.last}", size: 8, color: "6B7280"
      pdf.move_down 10

      yield pdf

      pdf.number_pages "<page>/<total>", at: [ pdf.bounds.right - 50, 0 ], size: 8
      pdf.render
    end

    def render_table(pdf, data)
      pdf.table(data, header: true, cell_style: { size: FONT_SIZE, padding: [ 4, 6 ] }) do
        row(0).font_style = :bold
        row(0).background_color = HEADER_COLOR
        row(0).text_color = HEADER_TEXT
        row(-1).font_style = :bold if data.length > 2
      end
    end

    def format_number(value)
      return "0.00" unless value
      format("%.2f", value.to_f)
    end

    def convert_amount(amount_ron, currency:)
      CurrencyConverter.convert(amount_ron, currency: currency) || amount_ron.to_d
    end
  end
end
