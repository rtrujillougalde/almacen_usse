module Reportes
  module Filename
    module_function

    # Mirrors src/p_reportes.py build_report_filename.
    def build(report_type:, date_from: nil, date_to: nil, cc: nil, extension:)
      cc_str = cc.present? ? "_cc_#{cc}" : ""
      fecha_str =
        if date_from.present? && date_to.present?
          from = Date.parse(date_from.to_s)
          to = Date.parse(date_to.to_s)
          "_#{from.strftime('%d%m%Y')}_a_#{to.strftime('%d%m%Y')}"
        else
          ""
        end

      "reporte_#{report_type}#{fecha_str}#{cc_str}.#{extension}"
    end
  end
end
