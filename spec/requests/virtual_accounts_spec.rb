require "rails_helper"

RSpec.describe "VirtualAccounts", type: :request do
  let(:valid_attributes) do
    {
      user_id: create(:user).id,
      account_number: "VA#{Faker::Number.number(digits: 10)}",
      cbs_account_number: "CBS#{Faker::Number.number(digits: 10)}",
      balance: Faker::Number.decimal(l_digits: 5, r_digits: 2),
      interest_rate: Faker::Number.decimal(l_digits: 2, r_digits: 2),
      interest_type: %w[simple compound].sample,
      active: true,
      branch_code: "BR001",
      product_scheme: %w[SAVINGS CURRENT LOAN].sample,
      voucher_type: "REGULAR",
      status: "active"
    }
  end

  let(:invalid_attributes) do
    {
      user_id: nil,
      account_number: nil,
      cbs_account_number: nil,
      branch_code: nil
    }
  end

  let(:new_attributes) do
    {
      status: "pending"
    }
  end

  include_examples "request_shared_spec", "virtual_accounts", 15
end
