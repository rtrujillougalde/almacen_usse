# Visual constants mirrored from src/pdf_styles.py for PDF parity with the Streamlit app.
module Reportes
  module PdfStyles
    INCH = 72

    TABLE_HEADER_COLOR = "FFFFFF"
    TABLE_ROW_ALT_COLOR = "6FB2C1"
    TABLE_ROW_BASE_COLOR = "FFFFFF"
    TABLE_TEXT_COLOR = "000000"
    TABLE_GRID_COLOR = "D3D3D3"

    TITLE_COLOR = "0A3FCB"
    SUMMARY_COLOR = "0E1117"
    TITLE_FONT_SIZE = 20
    SUMMARY_FONT_SIZE = 12
    TABLE_HEADER_FONT_SIZE = 10
    TABLE_BODY_FONT_SIZE = 8
    MATERIAL_FONT_SIZE = 8

    ENTRADAS_TOTAL_COLOR = "1F77B4"
    ENTRADAS_TOTAL_FONT_SIZE = 12
    PAGE_NUMBER_FONT_SIZE = 8
    PAGE_NUMBER_COLOR = "5F6368"

    LOGO_X = 40
    LOGO_FIRST_PAGE_Y_OFFSET = 72
    LOGO_LATER_PAGE_Y_OFFSET = 60
    LOGO_FIRST_PAGE_WIDTH = 1.6 * INCH
    LOGO_FIRST_PAGE_HEIGHT = 0.7 * INCH
    LOGO_LATER_PAGE_WIDTH = 1.2 * INCH
    LOGO_LATER_PAGE_HEIGHT = 0.5 * INCH

    COL_WIDTHS = [
      1.15 * INCH, # Fecha/Hora
      2.1 * INCH,  # Material
      0.75 * INCH, # Cantidad
      0.75 * INCH, # Unidad
      0.95 * INCH, # Precio Unit.
      0.95 * INCH  # Total
    ].freeze

    COL_WIDTHS_COMP = [
      2.05 * INCH,
      0.65 * INCH,
      0.55 * INCH,
      0.8 * INCH,
      0.7 * INCH,
      0.7 * INCH,
      0.7 * INCH,
      1.2 * INCH
    ].freeze

    REPORTE_TABLE_TOTAL_WIDTH = COL_WIDTHS.sum
    COL_WIDTHS_METADATA = [
      REPORTE_TABLE_TOTAL_WIDTH / 3.0,
      REPORTE_TABLE_TOTAL_WIDTH / 3.0,
      REPORTE_TABLE_TOTAL_WIDTH / 3.0
    ].freeze

    def self.logo_path
      Rails.root.join("app/assets/images/logo_usse_2.jpg")
    end
  end
end
