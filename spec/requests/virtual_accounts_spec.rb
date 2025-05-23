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
      status: "pending"
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
      status: "active"
    }
  end

  include_examples "request_shared_spec", "virtual_accounts", 15

  describe "GET /virtual_accounts/verified_accounts" do
    it "returns verified accounts" do
      active_account = create(:virtual_account, status: :active)
      pending_account = create(:virtual_account, status: :pending)
      suspended_account = create(:virtual_account, status: :suspended)

      get verified_accounts_virtual_accounts_path
      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response.first["id"]).to eq(active_account.id)
      expect(json_response.map { |a| a["id"] }).not_to include(pending_account.id, suspended_account.id)
    end
  end

  describe "PUT /virtual_accounts/:id/approve" do
    let(:virtual_account) { create(:virtual_account, status: :pending) }

    it "approves a pending virtual account" do
      put approve_virtual_account_path(virtual_account)
      expect(response).to have_http_status(:ok)
      expect(virtual_account.reload.status).to eq("active")
    end
  end

  describe "PUT /virtual_accounts/:id/suspend" do
    let(:virtual_account) { create(:virtual_account, status: :pending) }

    it "suspends a pending virtual account" do
      put suspend_virtual_account_path(virtual_account)
      expect(response).to have_http_status(:ok)
      expect(virtual_account.reload.status).to eq("suspended")
    end
  end
end
