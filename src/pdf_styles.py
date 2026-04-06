from reportlab.lib import colors
from reportlab.lib.units import inch


PDF_TABLE_HEADER_COLOR = colors.white
PDF_TABLE_ROW_ALT_COLOR = colors.HexColor("#6FB2C1")
PDF_TABLE_ROW_BASE_COLOR = colors.white
PDF_TABLE_TEXT_COLOR = colors.black
PDF_TABLE_GRID_COLOR = colors.HexColor("#D3D3D3")

PDF_TITLE_COLOR = colors.HexColor("#0A3FCB")
PDF_CC_COLOR = colors.HexColor("#0E1117")
PDF_SUMMARY_COLOR = colors.HexColor("#0E1117")
PDF_TITLE_FONT_SIZE = 20
PDF_CC_FONT_SIZE = 14
PDF_SUMMARY_FONT_SIZE = 12
PDF_TABLE_HEADER_FONT_SIZE = 10
PDF_TABLE_BODY_FONT_SIZE = 8
PDF_TABLE_HEADER_PADDING = 8
PDF_MATERIAL_FONT_SIZE = 8
PDF_MATERIAL_LEADING = 9
PDF_COL_WIDTHS_COMP = [
	2.05 * inch,
	0.65 * inch,
	0.55 * inch,
	0.8 * inch,
	0.7 * inch,
	0.7 * inch,
	0.7 * inch,
	1.2 * inch,
]


PDF_ENTRADAS_TOTAL_COLOR = colors.HexColor("#1F77B4")
PDF_ENTRADAS_TOTAL_FONT_SIZE = 12
PDF_PAGE_NUMBER_FONT = "Helvetica"
PDF_PAGE_NUMBER_FONT_SIZE = 8
PDF_PAGE_NUMBER_COLOR = colors.HexColor("#5F6368")
PDF_LOGO_X = 40
PDF_LOGO_FIRST_PAGE_Y_OFFSET = 72
PDF_LOGO_LATER_PAGE_Y_OFFSET = 60
PDF_LOGO_FIRST_PAGE_WIDTH = 1.6 * inch
PDF_LOGO_FIRST_PAGE_HEIGHT = 0.7 * inch
PDF_LOGO_LATER_PAGE_WIDTH = 1.2 * inch
PDF_LOGO_LATER_PAGE_HEIGHT = 0.5 * inch

PDF_COL_WIDTHS = [
            1.15 * inch,   #fecha/hora
            2.1 * inch, #material
            0.75 * inch,#cantidad
            0.75 * inch, #unidad
            0.95 * inch, #precio unitario
            0.95 * inch, #total
        ]
PDF_REPORTE_TABLE_TOTAL_WIDTH = sum(PDF_COL_WIDTHS)
PDF_COL_WIDTHS_METADATA = [
	PDF_REPORTE_TABLE_TOTAL_WIDTH / 3,
	PDF_REPORTE_TABLE_TOTAL_WIDTH / 3,
	PDF_REPORTE_TABLE_TOTAL_WIDTH / 3,
]

PDF_TABLE_METADATA = [
	("BACKGROUND", (0, 0), (-1, 0), PDF_TABLE_HEADER_COLOR),
	("TEXTCOLOR", (0, 0), (-1, -1), PDF_TABLE_TEXT_COLOR),
	("ALIGN", (0, 0), (-1, -1), "CENTER"),
	("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
	("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
	("FONTSIZE", (0, 0), (-1, 0), PDF_TABLE_HEADER_FONT_SIZE),
	("BOTTOMPADDING", (0, 0), (-1, 0), PDF_TABLE_HEADER_PADDING),
	("GRID", (0, 0), (-1, -1), 1, PDF_TABLE_GRID_COLOR),
	("FONTSIZE", (0, 1), (-1, -1), PDF_TABLE_BODY_FONT_SIZE),
	("ROWBACKGROUNDS", (0, 1), (-1, -1), [PDF_TABLE_ROW_ALT_COLOR, PDF_TABLE_ROW_BASE_COLOR]),
]

PDF_TABLE_STYLE_COMPARACION = [
	("BACKGROUND", (0, 0), (-1, 0), PDF_TABLE_HEADER_COLOR),
	("TEXTCOLOR", (0, 0), (-1, -1), PDF_TABLE_TEXT_COLOR),
	("ALIGN", (0, 0), (-1, -1), "CENTER"),
	("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
	("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
	("FONTSIZE", (0, 0), (-1, 0), PDF_TABLE_HEADER_FONT_SIZE),
	("BOTTOMPADDING", (0, 0), (-1, 0), PDF_TABLE_HEADER_PADDING),
	("GRID", (0, 0), (-1, -1), 1, PDF_TABLE_GRID_COLOR),
	("FONTSIZE", (0, 1), (-1, -1), PDF_TABLE_BODY_FONT_SIZE),
	("ROWBACKGROUNDS", (0, 1), (-1, -1), [PDF_TABLE_ROW_ALT_COLOR, PDF_TABLE_ROW_BASE_COLOR]),
]


PDF_TABLE_STYLE_REPORTE = [
	("BACKGROUND", (0, 0), (-1, 0), PDF_TABLE_HEADER_COLOR),
	("TEXTCOLOR", (0, 0), (-1, -1), PDF_TABLE_TEXT_COLOR),
	("ALIGN", (0, 0), (-1, -1), "CENTER"),
	("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
	("FONTSIZE", (0, 0), (-1, 0), PDF_TABLE_HEADER_FONT_SIZE),
	("BOTTOMPADDING", (0, 0), (-1, 0), PDF_TABLE_HEADER_PADDING),
	("GRID", (0, 0), (-1, -1), 1, PDF_TABLE_GRID_COLOR),
	("FONTSIZE", (0, 1), (-1, -1), PDF_TABLE_BODY_FONT_SIZE),
	("ROWBACKGROUNDS", (0, 1), (-1, -1), [PDF_TABLE_ROW_ALT_COLOR, PDF_TABLE_ROW_BASE_COLOR]),
]


def draw_pdf_page_number(canvas, doc):
	"""Dibuja la numeracion de pagina en el pie del PDF."""
	canvas.saveState()
	canvas.setFont(PDF_PAGE_NUMBER_FONT, PDF_PAGE_NUMBER_FONT_SIZE)
	canvas.setFillColor(PDF_PAGE_NUMBER_COLOR)
	page_number_text = f"Pagina {canvas.getPageNumber()}"
	canvas.drawRightString(doc.pagesize[0] - doc.rightMargin, 14, page_number_text)
	canvas.restoreState()