namespace :stock do
  desc "Report cables whose cached stock disagrees with the puntas on the shelf"
  task drift: :environment do
    # Reports only. Fixing is a separate, deliberate act: call
    # articulo.recalculate_stock! on the rows you have decided to trust.
    drifted = Articulo.where(es_cable: true).includes(:stock_puntas).filter_map do |articulo|
      drift = articulo.stock_drift
      [ articulo, drift ] if drift && !drift.zero?
    end

    if drifted.empty?
      puts "Sin diferencias: el stock de cables coincide con sus puntas."
      next
    end

    puts "#{drifted.size} cable(s) con diferencias:"
    drifted.each do |articulo, drift|
      puts format(
        "  %-40.40s  almacenado %10.2f  puntas %10.2f  diferencia %+.2f",
        articulo.nombre, articulo.cantidad_en_stock.to_f, articulo.derived_stock, drift
      )
    end
  end
end
