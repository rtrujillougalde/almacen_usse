module Movimientos
  Result = Struct.new(:success?, :movimiento, :error, keyword_init: true)
end
