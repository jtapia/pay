# Mercadopago configuration

Pay.mercadopago_gateway = Mercadopago::SDK.new(
  'TEST-101154492994844-072514-3e375718fe8951a68880d0220726e27b-80779781'
)

class ActiveSupport::TestCase
  private

  def fake_mercadopago_card_token
    card_token_object = {
      card_number: '5031433215406351',
      expiration_year: 2025,
      expiration_month: 11,
      security_code: '123',
      payment_method_id: 'visa',
      cardholder: {
        name: 'APRO'
      }
    }

    result = Pay.mercadopago_gateway.card_token.create(card_token_object)
    OpenStruct.new(result[:response])
  end
end
