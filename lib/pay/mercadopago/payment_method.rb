# frozen_string_literal: true

module Pay
  module Mercadopago
    class PaymentMethod
      attr_reader :pay_payment_method

      delegate :customer, :processor_id, to: :pay_payment_method

      def initialize(pay_payment_method)
        @pay_payment_method = pay_payment_method
      end

      def self.sync(id, object: nil, try: 0, retries: 1)
        object ||= ::Mercadopago::PaymentMethod.get(id, mercadopago_options)

        pay_customer = Pay::Customer.find_by(
          processor: :mercadopago,
          processor_id: object.customer_id
        )
        return unless pay_customer

        pay_customer.save_payment_method(object, default: object.default?)
      end

      # Extracts payment method details from a Mercadopago::PaymentMethod object
      def self.extract_attributes(payment_method)
        details = payment_method.try(payment_method.type)

        {
          payment_method_type: payment_method.type,
          email: details.try(:email), # Link
          brand: details.try(:brand)&.capitalize,
          last4: details.try(:last4).to_s,
          exp_month: details.try(:exp_month).to_s,
          exp_year: details.try(:exp_year).to_s,
          bank: details.try(:bank_name) || details.try(:bank)
        }
      end

      # Sets payment method as default
      def make_default!
        ::Mercadopago::Customer.update(
          customer.processor_id,
          mercadopago_options
        )
      end

      # Remove payment method
      def detach
        ::Mercadopago::PaymentMethod.detach(
          processor_id,
          mercadopago_options
        )
      end

      private

      # Options for Stripe requests
      def mercadopago_options
        {}.compact
      end
    end
  end
end
