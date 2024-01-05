# frozen_string_literal: true

module Pay
  module Webhooks
    class MercadopagoController < Pay::ApplicationController
      # if Rails.application.config.action_controller.default_protect_from_forgery
      #   skip_before_action :verify_authenticity_token
      # end

      # def create
      #   queue_event(verified_event)
      #   head :ok
      # rescue ::Mercadopago::InvalidSignature
      #   head :bad_request
      # end

      # private

      # def queue_event(event)
      #   return unless Pay::Webhooks.delegator.listening?("mercadopago.#{event.kind}")

      #   record = Pay::Webhook.create!(
      #     processor: :mercadopago,
      #     event_type: event.kind,
      #     event: {
      #       bt_signature: params[:bt_signature],
      #       bt_payload: params[:bt_payload]
      #     }
      #   )

      #   Pay::Webhooks::ProcessJob.perform_later(record)
      # end

      # def verified_event
      #   binding.pry
      #   Pay.mercadopago_gateway.webhook_notification.parse(
      #     params[:bt_signature],
      #     params[:bt_payload]
      #   )
      # end
    end
  end
end
