# frozen_string_literal: true

require "caxlsx"

class XlsxExporter
  class << self
    def labour_by_project(data, detail: [], currency: "RON")
      summary_columns = ["Project", "Worker", "Days", "Cost_#{currency}"]
      summary_rows = []

      data.each do |row|
        project_name = row[:project]&.name || "Unknown"

        (row[:workers] || []).each do |worker_row|
          summary_rows << [
            project_name,
            worker_row[:worker]&.full_name || "Unknown",
            worker_row[:days].to_i,
            convert_amount(worker_row[:cost_ron], currency: currency)
          ]
        end
      end

      sheets = [{ name: "Summary", columns: summary_columns, rows: summary_rows, sum_columns: [3] }]
      sheets << labour_detail_sheet(detail, currency: currency) if detail.any?

      build_workbook(sheets: sheets, currency: currency)
    end

    def labour_summary(data, detail: [], currency: "RON")
      summary_columns = ["Project", "Total_Days", "Total_Cost_#{currency}"]
      summary_rows = data.map do |row|
        [
          row[:project]&.name || "Unknown",
          row[:total_days].to_i,
          convert_amount(row[:total_cost_ron], currency: currency)
        ]
      end

      sheets = [{ name: "Summary", columns: summary_columns, rows: summary_rows, sum_columns: [1, 2] }]
      sheets << labour_detail_sheet(detail, currency: currency) if detail.any?

      build_workbook(sheets: sheets, currency: currency)
    end

    def materials_by_project(data, currency: "RON")
      # Summary: one row per project
      summary_columns = [
        "Project",
        "Total_Ex_VAT_#{currency}",
        "Total_VAT_#{currency}",
        "Total_Inc_VAT_#{currency}"
      ]

      summary_rows = data.map do |row|
        [
          row[:project]&.name || "Unknown",
          convert_amount(row[:total_ex_vat_ron], currency: currency),
          convert_amount(row[:total_vat_ron], currency: currency),
          convert_amount(row[:total_inc_vat_ron], currency: currency)
        ]
      end

      # Detail: individual entries
      detail_columns = [
        "Date", "Project", "Phase", "Task", "Description", "Quantity", "Unit",
        "Unit_Cost_Ex_VAT_#{currency}", "Total_Ex_VAT_#{currency}",
        "VAT_Rate", "VAT_#{currency}", "Total_Inc_VAT_#{currency}", "Supplier"
      ]

      detail_rows = []
      data.each do |row|
        project_name = row[:project]&.name || "Unknown"

        (row[:entries] || []).each do |entry|
          detail_rows << [
            entry.date.to_s,
            project_name,
            entry.task&.phase&.name || "",
            entry.task&.name || "",
            entry.description,
            entry.quantity,
            entry.unit,
            convert_amount(entry.unit_cost_ex_vat_ron, currency: currency),
            convert_amount(entry.total_cost_ex_vat_ron, currency: currency),
            entry.vat_rate.to_f,
            convert_amount(entry.total_vat_ron, currency: currency),
            convert_amount(entry.total_cost_inc_vat_ron, currency: currency),
            entry.supplier_name
          ]
        end
      end

      sheets = [
        { name: "Summary", columns: summary_columns, rows: summary_rows, sum_columns: [1, 2, 3] },
        { name: "Materials Detail", columns: detail_columns, rows: detail_rows, sum_columns: [5, 7, 8, 10, 11] }
      ]

      build_workbook(sheets: sheets, currency: currency)
    end

    def combined_cost(data, labour_detail: [], materials_detail: [], currency: "RON")
      summary_columns = [
        "Project",
        "Labour_#{currency}",
        "Materials_Ex_VAT_#{currency}",
        "Materials_VAT_#{currency}",
        "Materials_Inc_VAT_#{currency}",
        "Total_#{currency}"
      ]

      summary_rows = data.map do |row|
        [
          row[:project]&.name || "Unknown",
          convert_amount(row[:labour_cost_ron], currency: currency),
          convert_amount(row[:materials_ex_vat_ron], currency: currency),
          convert_amount(row[:materials_vat_ron], currency: currency),
          convert_amount(row[:materials_inc_vat_ron], currency: currency),
          convert_amount(row[:total_ron], currency: currency)
        ]
      end

      sheets = [{ name: "Summary", columns: summary_columns, rows: summary_rows, sum_columns: [1, 2, 3, 4, 5] }]
      sheets << labour_detail_sheet(labour_detail, currency: currency) if labour_detail.any?
      sheets << materials_detail_sheet(materials_detail, currency: currency) if materials_detail.any?

      build_workbook(sheets: sheets, currency: currency)
    end

    private

    def labour_detail_sheet(detail, currency:)
      columns = [
        "Date", "Project", "Phase", "Task", "Worker",
        "Hours", "Scope", "Daily_Rate_#{currency}", "Cost_#{currency}"
      ]

      rows = detail.map do |row|
        [
          row[:log_date].to_s,
          row[:project_name],
          row[:phase_name] || "",
          row[:task_name] || "",
          row[:worker_name],
          row[:hours_worked],
          row[:scope] || "",
          convert_amount(row[:daily_rate_ron], currency: currency),
          convert_amount(row[:cost_ron], currency: currency)
        ]
      end

      { name: "Labour Detail", columns: columns, rows: rows, sum_columns: [5, 8] }
    end

    def materials_detail_sheet(entries_data, currency:)
      columns = [
        "Date", "Project", "Phase", "Task", "Description", "Quantity", "Unit",
        "Unit_Cost_Ex_VAT_#{currency}", "Total_Ex_VAT_#{currency}",
        "VAT_Rate", "VAT_#{currency}", "Total_Inc_VAT_#{currency}", "Supplier"
      ]

      rows = entries_data.map do |entry|
        [
          entry[:date].to_s,
          entry[:project_name],
          entry[:phase_name] || "",
          entry[:task_name] || "",
          entry[:description],
          entry[:quantity],
          entry[:unit],
          convert_amount(entry[:unit_cost_ex_vat_ron], currency: currency),
          convert_amount(entry[:total_cost_ex_vat_ron], currency: currency),
          entry[:vat_rate].to_f,
          convert_amount(entry[:total_vat_ron], currency: currency),
          convert_amount(entry[:total_cost_inc_vat_ron], currency: currency),
          entry[:supplier_name]
        ]
      end

      { name: "Materials Detail", columns: columns, rows: rows, sum_columns: [5, 7, 8, 10, 11] }
    end

    def build_workbook(sheets:, currency:)
      package = Axlsx::Package.new
      package.use_shared_strings = true
      workbook = package.workbook

      header_style, text_style, number_style, total_style = styles_for(workbook)

      sheets.each do |sheet_def|
        workbook.add_worksheet(name: sheet_def[:name]) do |sheet|
          columns = sheet_def[:columns]
          rows = sheet_def[:rows]
          sum_cols = sheet_def[:sum_columns] || []

          safe_columns = sanitize_row(columns)
          sheet.add_row(safe_columns, style: Array.new(safe_columns.length, header_style))

          rows.each do |row|
            safe_row = sanitize_row(row)
            styles = safe_row.map { |value| numeric_value?(value) ? number_style : text_style }
            sheet.add_row(safe_row, style: styles)
          end

          add_formula_footer(sheet, columns.length, rows.length, sum_cols, total_style, number_style) if rows.any? && sum_cols.any?
          add_table_with_filters(sheet, columns.length, rows.length)
          freeze_header_row(sheet)
        end
      end

      package.to_stream.read
    end

    def add_formula_footer(sheet, column_count, row_count, sum_columns, total_style, number_style)
      footer = Array.new(column_count, "")
      footer[0] = "TOTAL"
      styles = Array.new(column_count, total_style)

      last_data_row = row_count + 1
      sum_columns.each do |col_idx|
        col_letter = excel_column(col_idx + 1)
        footer[col_idx] = "=SUM(#{col_letter}2:#{col_letter}#{last_data_row})"
        styles[col_idx] = number_style
      end

      sheet.add_row(footer, style: styles, escape_formulas: false)
    end

    def add_table_with_filters(sheet, column_count, row_count)
      return if row_count.zero?

      last_column = excel_column(column_count)
      last_row = row_count + 1
      reference = "A1:#{last_column}#{last_row}"

      sheet.add_table(reference, name: table_name(sheet.name), style_info: {
        name: "TableStyleMedium2",
        show_first_column: false,
        show_last_column: false,
        show_row_stripes: true,
        show_column_stripes: false
      })
    end

    def freeze_header_row(sheet)
      sheet.sheet_view.pane do |pane|
        pane.top_left_cell = "A2"
        pane.state = :frozen
        pane.y_split = 1
        pane.active_pane = :bottom_left
      end
    end

    def styles_for(workbook)
      styles = workbook.styles
      header_style = styles.add_style(
        b: true,
        bg_color: "4B5563",
        fg_color: "FFFFFF",
        alignment: { horizontal: :center }
      )
      text_style = styles.add_style(alignment: { horizontal: :left })
      number_style = styles.add_style(num_fmt: 2, alignment: { horizontal: :right })
      total_style = styles.add_style(
        b: true,
        bg_color: "F3F4F6",
        alignment: { horizontal: :left }
      )

      [ header_style, text_style, number_style, total_style ]
    end

    def numeric_value?(value)
      value.is_a?(Numeric) || value.is_a?(BigDecimal)
    end

    def sanitize_row(row)
      row.map do |value|
        next value if numeric_value?(value) || value.nil?

        value.to_s
             .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
             .gsub(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/, "")
      end
    end


    def excel_column(index)
      name = +""
      current = index

      while current > 0
        current -= 1
        name.prepend(("A".ord + (current % 26)).chr)
        current /= 26
      end

      name
    end

    def table_name(sheet_name)
      "#{sheet_name.gsub(/\W/, "")}Data"
    end

    def convert_amount(amount_ron, currency:)
      (CurrencyConverter.convert(amount_ron, currency: currency) || amount_ron.to_d.round(2)).to_f
    end
  end
end