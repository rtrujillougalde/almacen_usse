module Movimientos
  # Turns add_item params into a CartItem, or into a message for the flash.
  #
  # Returns [item, nil] or [nil, "message"], the pair the movement controllers
  # already destructure. cart_items is the cart as it stands, which salidas
  # needs to reject a punta that is already in the current movement.
  class CartItemBuilder
    def self.call(params, cart_items: [])
      new(params, cart_items: cart_items).call
    end

    def initialize(params, cart_items: [])
      @params = params
      @cart_items = cart_items
    end

    def call
      raise NotImplementedError
    end

    private

    attr_reader :params, :cart_items

    def item(attributes)
      [ CartItem.new(attributes), nil ]
    end

    def error(*messages)
      [ nil, messages.flatten.compact_blank.join(". ") ]
    end

    def boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
