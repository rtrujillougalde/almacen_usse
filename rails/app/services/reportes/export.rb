module Reportes
  # Picks the generator and MIME type for a report download and names the file.
  # Returns the keyword arguments send_data needs.
  class Export
    CONTENT_TYPES = {
      "pdf" => "application/pdf",
      "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    }.freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(kind:, cc:, rows:, format:, date_from: nil, date_to: nil)
      @kind = kind
      @cc = cc
      @rows = rows
      @format = CONTENT_TYPES.key?(format) ? format : "pdf"
      @date_from = date_from
      @date_to = date_to
    end

    def call
      {
        data: @format == "pdf" ? pdf : xlsx,
        filename: filename,
        type: CONTENT_TYPES.fetch(@format)
      }
    end

    private

    # "utilizado" is the one report built from grouped rows rather than a flat
    # list of movements.
    def utilizado?
      @kind == "utilizado"
    end

    def pdf
      if utilizado?
        PdfGenerator.utilizado(cc: @cc, groups: @rows)
      else
        PdfGenerator.movement(movement_type: @kind, cc: @cc, rows: @rows)
      end
    end

    def xlsx
      if utilizado?
        ExcelGenerator.utilizado(groups: @rows)
      else
        ExcelGenerator.movement(movement_type: @kind, rows: @rows)
      end
    end

    def filename
      Filename.build(
        report_type: @kind,
        date_from: @date_from,
        date_to: @date_to,
        cc: @cc,
        extension: @format
      )
    end
  end
end
