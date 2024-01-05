# frozen_string_literal: true

module Pay
  module Mercadopago
    class Billable
      attr_reader :pay_customer

      delegate :processor_id,
        :processor_id?,
        :email,
        :customer_name,
        :payment_method_token,
        :payment_method_token?,
        to: :pay_customer

      def self.default_url_options
        Rails.application.config.action_mailer.default_url_options || {}
      end

      def initialize(pay_customer)
        @pay_customer = pay_customer
      end

      # Returns a hash of attributes for the Mercadopago::Customer object
      def customer_attributes
        owner = pay_customer.owner

        attributes = case owner.class.pay_mercadopago_customer_attributes
        when Symbol
          owner.send(owner.class.pay_mercadopago_customer_attributes, pay_customer)
        when Proc
          owner.class.pay_mercadopago_customer_attributes.call(pay_customer)
        end

        # Guard against attributes being returned nil
        attributes ||= {}

        { email: email, name: customer_name }.merge(attributes)
      end

      # Retrieves a Mercadopago::Customer object
      #
      # Finds an existing Mercadopago::Customer if processor_id exists
      # Creates a new Mercadopago::Customer using `customer_attributes` if empty processor_id
      #
      # Updates the default payment method automatically if a payment_method_token is set
      #
      # Returns a Mercadopago::Customer object
      def customer
        mercadopago_customer = if processor_id?
          OpenStruct.new(gateway.customer.get(processor_id))
        else
          result = OpenStruct.new(gateway.customer.create(customer_attributes))
          raise Pay::Mercadopago::Error, result unless result.status.in?([200, 201])

          response = OpenStruct.new(result.response)
          pay_customer.update!(processor_id: response.id)
          response
        end

        if payment_method_token?
          add_payment_method(payment_method_token, default: true)
          pay_customer.payment_method_token = nil
        end

        mercadopago_customer
      rescue => e
        raise Pay::Mercadopago::Error, e
      end

      # Syncs name and email to Mercadopago::Customer
      # You can also pass in other attributes that will be merged into
      # the default attributes
      def update_customer!(**attributes)
        customer unless processor_id?

        gateway.customer.update(
          processor_id,
          customer_attributes.merge(attributes)
        )
      end

      # Charges an amount to the customer's default payment method
      def charge(amount, options = {})
        args = {
          token: options&.id,
          installments: 1,
          transaction_amount: amount,
          payer: {
            type: 'customer',
            id: pay_customer.processor_id
          }
        }

        payment = OpenStruct.new(gateway.payment.create(args))
        response = OpenStruct.new(payment.response)
        raise Pay::Mercadopago::Error, response.message unless payment.status.in?([200, 201])

        Pay::Payment.new(payment).validate
        response
      rescue => e
        raise Pay::Mercadopago::Error, e
      end

      def add_payment_method(token, default: false)
        customer unless processor_id?

        result = gateway.payment_method.create(
          customer_id: processor_id,
          payment_method_nonce: token,
          options: {
            make_default: default,
            verify_card: true
          }
        )
        raise Pay::Mercadopago::Error, result unless result.success?

        pay_payment_method = save_payment_method(result.payment_method, default: default)

        # Update existing subscriptions to the new payment method
        pay_customer.subscriptions.each do |subscription|
          if subscription.active?
            gateway.subscription.update(subscription.processor_id, {payment_method_token: token})
          end
        end

        pay_payment_method
      rescue => e
        raise Pay::Mercadopago::Error, e
      end

      # Save the Mercadopago::PaymentMethod to the database
      def save_payment_method(payment_method, default:)
        attributes = {
          payment_method_type: payment_method.class.name.demodulize.underscore,
          brand: payment_method.try(:card_type),
          last4: payment_method.try(:last_4),
          exp_month: payment_method.try(:expiration_month),
          exp_year: payment_method.try(:expiration_year),
          bank: payment_method.try(:bank_name),
          username: payment_method.try(:username),
          email: payment_method.try(:email)
        }

        pay_payment_method = pay_customer.payment_methods.where(
          processor_id: payment_method.token
        ).first_or_initialize
        pay_customer.payment_methods.update_all(default: false) if default
        pay_payment_method.update!(attributes.merge(default: default))

        # Reload the Rails association
        pay_customer.reload_default_payment_method if default

        pay_payment_method
      end

      def authorize(amount, options = {})
        charge(amount, options.merge(capture_method: :manual))
      end

      def gateway
        Pay.mercadopago_gateway
      end

      private

      # Options for Mercadopago requests
      def mercadopago_options
        {}.compact
      end
    end
  end
end
