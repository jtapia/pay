# frozen_string_literal: true

module Pay
  module Mercadopago
    class Error < Pay::Error
      attr_reader :result

      def cause
        super || result
      end
    end
  end
end
