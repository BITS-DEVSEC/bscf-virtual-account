require "rails_helper"

RSpec.describe "VirtualAccountTransactions", type: :request do
  let(:valid_attributes) do
    {
      from_account_id: create(:virtual_account, status: :active, cbs_account_number: "test1", balance: 10000.00).id,
      to_account_id: create(:virtual_account, status: :active, cbs_account_number: "test2").id,
      amount: Faker::Number.decimal(l_digits: 4, r_digits: 2),
      transaction_type:  "transfer",
      status: "pending",
      description: Faker::Lorem.sentence
    }
  end

  let(:invalid_attributes) do
    {
      from_account_id: nil,
      to_account_id: nil,
      amount: 100.5,
      transaction_type: "transfer",
      status: "pending",
      description: "Test transfer"
    }
  end

  let(:new_attributes) do
    {
      status: "completed"
    }
  end

  include_examples "request_shared_spec", "virtual_account_transactions", 11
end
