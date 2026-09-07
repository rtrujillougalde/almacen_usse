# Material utilizado report

## Problem

The Comparativo report only compares entradas vs salidas (`usado = salidas − entradas`). Purchases (`compra`) are now first-class movements, so that number is not the real material used on a project.

## Goal

Remove Comparativo from the Rails Reportes page and replace it with **Material utilizado**: one aggregated row per article for a cost center, using compras and the tool depreciation rule.

## Decisions

- Replace Comparativo with Material utilizado. Do not keep both.
- Show the quantity breakdown plus catalog price and cost, like Comparativo.
- Materials: `utilizado = compras + salidas − entradas`; `costo = catalog price × utilizado`.
- Tools (`herramienta`): ignore entradas for utilizado and cost. `utilizado = compras + salidas`; `costo = catalog price × utilizado × 0.05`. Tools are always charged this way even if later marked as entrada.
- Price source is `articulos.precio_unitario` (catalog / original price).
- Replace Comparativo in place (`kind` = `utilizado`). Not a fifth report type.
- Columns: C.C, Material, Tipo, Unidad, Precio Unit., Compras, Salidas, Entradas, Utilizado, Costo. Keep the Costo Total footer.
- Tools still list Entradas; that quantity is not subtracted from Utilizado or cost.
- Rails only. Do not change the old Python/Streamlit app.
- A material appears if it has any compra, salida, or entrada for that project in the filter window.
- Utilizado may be negative when a material was returned more than it was bought or taken. Still show the row.
- Never add or subtract MXN and USD. One table (and one Costo Total) per moneda.
- Compras use their own moneda. Entradas and salidas use the moneda of the most recent compra of that material on the same cost center. If there is no compra, they count as MXN.

## Formula (per article, per cost center)

| Type | Utilizado | Cost |
|------|-----------|------|
| material | compras + salidas − entradas | precio × utilizado |
| herramienta | compras + salidas | precio × utilizado × 0.05 |

Compras, Salidas, and Entradas columns are the raw sums for that article. Utilizado and Costo apply the type-specific rule above.

Same cost-center filter and optional date range as the other reports.

## UI

- Dropdown label: **Material utilizado**
- Generate button: **Generar Reporte de Material Utilizado**
- Info text: this report calculates real project usage as compras + salidas − entradas; tools use 5% depreciation and do not subtract entradas.
- Preview table uses the columns listed in Decisions.
- Success copy: count of materials/herramientas found.
- Empty copy: no movements found to calculate material utilizado.
- Download PDF / Excel stay on the results panel.

## Files

- PDF title: Reporte de Material Utilizado
- Filenames: `reporte_utilizado_cc_<cc>.pdf` / `.xlsx` (same date-range pattern as today when dates are on)

## Code

Replace Comparativo in the existing report pipeline:

- `Reportes::Query.utilizado_rows` replaces `comparativo_rows`
- `Reportes::PdfGenerator.utilizado` replaces `comparativo`
- `Reportes::ExcelGenerator.utilizado` replaces `comparativo`
- Controller kind allow-list: `entrada | salida | compra | utilizado`
- Filename `report_type`: `utilizado`

Load articles in one query (no `find_by` per row).

## Testing

Rewrite Comparativo specs to Material utilizado:

- Query: material used = compra + salida − entrada; tool used = compra + salida; costs match the table above
- Request: preview headers, Costo Total, generate + download for `kind=utilizado`
- PDF / Excel: new title, Compras column, Utilizado, Costo; no Comparativo labels
- Filename spec uses `utilizado` instead of `comparativo`

## Out of scope

- Python / Streamlit report
- Changing how compras, entradas, or salidas are recorded
- Changing catalog prices from this report
