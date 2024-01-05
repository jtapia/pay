require "test_helper"

class Pay::Mercadopago::BillableTest < ActiveSupport::TestCase
  setup do
    @pay_customer = Pay::Customer.create!(
      processor: :mercadopago,
      owner: users(:none)
    )
  end

  test "mercadopago customer" do
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      customer = @pay_customer.customer
      assert customer.id.present?
      assert_equal "none@example.org", customer.email
    end
  end

  test "customer attributes proc" do
    pay_customer = pay_customers(:mercadopago)
    original_value = User.pay_mercadopago_customer_attributes
    attributes = { metadata: { foo: :bar } }

    User.pay_mercadopago_customer_attributes = ->(pay_customer) { attributes }
    assert attributes <= Pay::Mercadopago::Billable.new(pay_customer).customer_attributes

    # Clean up
    User.pay_mercadopago_customer_attributes = original_value
  end

  test "mercadopago customer attributes symbol" do
    pay_customer = pay_customers(:mercadopago)
    original_value = User.pay_mercadopago_customer_attributes

    User.pay_mercadopago_customer_attributes = :mercadopago_attributes
    expected_value = pay_customer.owner.mercadopago_attributes(pay_customer)
    assert expected_value <= Pay::Mercadopago::Billable.new(pay_customer).customer_attributes

    # Clean up
    User.pay_mercadopago_customer_attributes = original_value
  end

  test "mercadopago fails with invalid cards" do
    # This requires Card Verification to be enabled in the Mercadopago account
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      @pay_customer.payment_method_token = "fake-processor-declined-visa-nonce"
      @pay_customer.processor_id = nil

      err = assert_raises(Pay::Mercadopago::Error) { @pay_customer.charge(29_00, OpenStruct.new) }
      assert_equal "payment_method_id attribute can't be null", err.message
    end
  end

  test "mercadopago can charge card with credit card" do
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      card_token = fake_mercadopago_card_token
      @pay_customer.payment_method_token = "fake-valid-visa-nonce"
      @pay_customer.processor_id = "1623739743-dxr2lARGFjjlBo"

      charge = @pay_customer.charge(29_00, card_token)
      assert_equal "credit_card", charge.payment_type_id
    end
  end

  test "mercadopago can charge card with Visa Checkout Card" do
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      card_token = fake_mercadopago_card_token
      @pay_customer.payment_method_token = "fake-visa-checkout-amex-nonce"
      @pay_customer.processor_id = "1623739743-dxr2lARGFjjlBo"

      charge = @pay_customer.charge(29_00, card_token)
      assert_equal "credit_card", charge.payment_type_id
    end
  end

  # Invalid amount will cause the transaction to fail
  # https://developers.mercadopagopayments.com/reference/general/testing/ruby#amount-200000-300099
  test "mercadopago handles charge failures" do
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      card_token = fake_mercadopago_card_token
      @pay_customer.payment_method_token = "fake-valid-visa-nonce"
      @pay_customer.processor_id = "1623739743-dxr2lARGFjjlBo"

      err = assert_raises(Pay::Mercadopago::Error) { @pay_customer.charge(2000_00, card_token) }
      assert_equal "Invalid card_token_id", err.message
    end
  end

  test "mercadopago email changed" do
    # Must already have a processor ID
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      card_token = fake_mercadopago_card_token
      @pay_customer.update(processor_id: "fake")

      Pay::CustomerSyncJob.expects(:perform_later).with(@pay_customer.id)
      @pay_customer.owner.update(email: "mynewemail@example.org")
    end
  end

  test "mercadopago fails charges with invalid cards" do
    # This requires Card Verification to be enabled in the Mercadopago account
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      card_token = fake_mercadopago_card_token
      @pay_customer.payment_method_token = "fake-processor-declined-visa-nonce"
      @pay_customer.processor_id = "1623739743-dxr2lARGFjjlBo"

      err = assert_raises(Pay::Mercadopago::Error) { @pay_customer.charge(10_00, card_token) }
      assert_equal "Invalid card_token_id", err.message
    end
  end
end
