# frozen_string_literal: true

require 'mercadopago'

module Pay
  module Mercadopago
    autoload :AuthorizationError, "pay/mercadopago/authorization_error"
    autoload :Billable, "pay/mercadopago/billable"
    autoload :Charge, "pay/mercadopago/charge"
    autoload :Error, "pay/mercadopago/error"
    autoload :PaymentMethod, "pay/mercadopago/payment_method"
    autoload :Subscription, "pay/mercadopago/subscription"

    module Webhooks
      # autoload :SubscriptionCanceled, "pay/mercadopago/webhooks/subscription_canceled"
      # autoload :SubscriptionChargedSuccessfully, "pay/mercadopago/webhooks/subscription_charged_successfully"
      # autoload :SubscriptionChargedUnsuccessfully, "pay/mercadopago/webhooks/subscription_charged_unsuccessfully"
      # autoload :SubscriptionExpired, "pay/mercadopago/webhooks/subscription_expired"
      # autoload :SubscriptionTrialEnded, "pay/mercadopago/webhooks/subscription_trial_ended"
      # autoload :SubscriptionWentActive, "pay/mercadopago/webhooks/subscription_went_active"
      # autoload :SubscriptionWentPastDue, "pay/mercadopago/webhooks/subscription_went_past_due"
    end

    extend Env

     REQUIRED_VERSION = "~> 2"

    def self.enabled?
      return false unless Pay.enabled_processors.include?(:mercadopago) && defined?(::Mercadopago)

      Pay::Engine.version_matches?(
        required: REQUIRED_VERSION, current: ::Mercadopago::Config.new.version) ||
        (raise "[Pay] mercadopago gem must be version #{REQUIRED_VERSION}"
      )
    end

    def self.setup
      ::Mercadopago::SDK.new(access_token)
    end

    def self.setup
      Pay.mercadopago_gateway = ::Mercadopago::SDK.new(access_token)
    end

    def self.public_key
      find_value_by_name(:mercadopago, :public_key)
    end

    def self.access_token
      find_value_by_name(:mercadopago, :access_token)
    end

    def self.configure_webhooks; end
  end
end
