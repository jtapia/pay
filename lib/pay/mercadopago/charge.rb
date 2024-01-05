# frozen_string_literal: true

module Pay
  module Mercadopago
    class Charge
      attr_reader :pay_charge

      delegate :processor_id, to: :pay_charge

      def self.sync(payment_id, object: nil, try: 0, retries: 1)
        binding.pry
        object ||= ::Mercadopago::Payment.get(payment_id)
        # object ||= Pay.braintree_gateway.transaction.find(charge_id)

        pay_customer = Pay::Customer.find_by(processor: :mercadopago, processor_id: object.payer.id)
        return unless pay_customer

        pay_customer.charges.create!(attrs.merge(processor_id: object.id))
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        try += 1
        if try <= retries
          sleep 0.1
          retry
        else
          raise
        end
      end

      def initialize(pay_charge)
        @pay_charge = pay_charge
      end

      def charge
        # sdk = Mercadopago::SDK.new('ENV_ACCESS_TOKEN')

        # custom_headers = {
        #  'x-idempotency-key': '<SOME_UNIQUE_VALUE>'
        # }

        # custom_request_options = Mercadopago::RequestOptions.new(custom_headers: custom_headers)
        # custom_request_options = Mercadopago::RequestOptions.new(custom_headers: custom_headers)
        binding.pry
        payment_request = {
          # token: 'ff8080814c11e237014c1ff593b57b4d',
          installments: 1,
          transaction_amount: object.amount,
          payer: {
            type: 'customer',
            id: pay_customer.id
          }
        }

        binding.pry
        payment_response = sdk.payment.create(payment_request, custom_request_options)
        payment = payment_response[:response]
        payment
        # Pay.braintree_gateway.transaction.find(processor_id)
      rescue => e
        raise Pay::Mercadopago::Error, e
      end

      def refund!(amount_to_refund)
        binding.pry
        # Pay.braintree_gateway
        # sdk.refund.create("payment_id")
        # sdk = Mercadopago::SDK.new('YOUR_ACCESS_TOKEN')

        data = { amount: amount_to_refund }

        binding.pry
        refund = sdk.refund.create(object.id, refund_data: data)
        pay_charge.update(amount_refunded: amount_to_refund)
        # Pay.braintree_gateway.transaction.refund(processor_id, amount_to_refund / 100.0)
      rescue => e
        raise Pay::Mercadopago::Error, e
      end
    end
  end
end
