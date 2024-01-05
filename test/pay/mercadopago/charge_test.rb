require "test_helper"

class Pay::Mercadopago::ChargeTest < ActiveSupport::TestCase
  setup do
    @pay_customer = pay_customers(:mercadopago)
    @pay_customer.update(processor_id: "1623739743-dxr2lARGFjjlBo")
  end

  test "mercadopago can partially refund a transaction" do
    card_token = fake_mercadopago_card_token
    @pay_customer.payment_method_token = "fake-valid-visa-nonce"

    charge = @pay_customer.charge(29_00, card_token)
    assert charge.present?
  end

  test "mercadopago can fully refund a transaction" do
    card_token = fake_mercadopago_card_token
    @pay_customer.payment_method_token = "fake-valid-visa-nonce"

    charge = @pay_customer.charge(37_00, card_token)
    assert charge.present?
  end

  test "you can ask the charge for the type" do
    assert pay_customers(:stripe).charges.new.stripe?
    refute pay_customers(:mercadopago).charges.new.stripe?

    assert pay_customers(:mercadopago).charges.new.mercadopago?
    refute pay_customers(:mercadopago).charges.new.stripe?

    assert pay_customers(:paddle_classic).charges.new.paddle_classic?
    refute pay_customers(:paddle_classic).charges.new.stripe?

    assert pay_customers(:fake).charges.new.fake_processor?
    refute pay_customers(:fake).charges.new.stripe?
  end

  test "mercadopago saves currency on charge" do
    card_token = fake_mercadopago_card_token
    @pay_customer.payment_method_token = "fake-valid-visa-nonce"

    charge = @pay_customer.charge(29_00, card_token)
    assert_equal "MXN", charge.currency_id
  end
end
