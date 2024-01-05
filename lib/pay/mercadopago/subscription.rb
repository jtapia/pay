# frozen_string_literal: true

module Pay
  module Mercadopago
    class Subscription
      attr_accessor :mercadopago_subscription
      attr_reader :pay_subscription

      delegate :active?,
        :canceled?,
        :ends_at?,
        :ends_at,
        :name,
        :on_trial?,
        :past_due?,
        :pause_starts_at,
        :pause_starts_at?,
        :processor_id,
        :processor_plan,
        :processor_subscription,
        :prorate,
        :prorate?,
        :quantity,
        :quantity?,
        :stripe_account,
        :subscription_items,
        :trial_ends_at,
        :pause_behavior,
        :pause_resumes_at,
        :current_period_start,
        :current_period_end,
        to: :pay_subscription
    end
  end
end
