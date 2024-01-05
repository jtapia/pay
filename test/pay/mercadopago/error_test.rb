require "test_helper"

class Pay::Mercadopago::ErrorTest < ActiveSupport::TestCase
  test "raising mercadopago failures keep the same message" do
    travel_to(VCR.current_cassette&.originally_recorded_at || Time.current) do
      pay_customer = pay_customers(:mercadopago)

      pay_customer.update(processor_id: nil)
      exception = assert_raises(Pay::Mercadopago::Error) { pay_customer.charge(0, OpenStruct.new) }
      assert_match "transaction_amount must be positive", exception.to_s
      assert_equal Pay::Mercadopago::Error, exception.cause.class
    end
  end
end
