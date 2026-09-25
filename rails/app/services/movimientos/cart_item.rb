module Movimientos
  # One line of a session cart.
  #
  # The cart lives in the cookie session, so items are stored as plain
  # string-keyed hashes; to_h is what goes in and what the views read back.
  # to_service_args is the same data as keyword arguments for the service,
  # which takes the keys it needs and ignores the rest.
  class CartItem
    def initialize(attributes)
      @attributes = attributes.to_h.transform_keys(&:to_s)
    end

    def to_h
      @attributes
    end

    def to_service_args
      args = @attributes.symbolize_keys
      # New items carry their own nombre; existing ones only carry the display
      # name the cart table shows.
      args[:nombre] = args[:nombre] || args[:nombre_item]
      args
    end
  end
end
