require "rails_helper"

RSpec.describe "VirtualAccounts", type: :request do
  let(:valid_attributes) do
    {
      user_id: create(:user).id,
      account_number: "VA#{Faker::Number.number(digits: 10)}",
      cbs_account_number: "CBS#{Faker::Number.number(digits: 10)}",
      balance: Faker::Number.decimal(l_digits: 5, r_digits: 2),
      locked_amount: 0.0,
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

  describe "GET /virtual_accounts/lookup_by_account_number" do
    let(:user) { create(:user, first_name: "John", middle_name: "Doo", last_name: "Smith") }
    let(:virtual_account) { create(:virtual_account, user: user, account_number: "VA1234567890") }

    context "with valid account number" do
      it "returns account holder information" do
        get lookup_by_account_number_virtual_accounts_path, params: { account_number: virtual_account.account_number }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response["success"]).to be_truthy
        expect(json_response["data"]["account_id"]).to eq(virtual_account.id)
        expect(json_response["data"]["account_number"]).to eq(virtual_account.account_number)
        expect(json_response["data"]["account_holder_name"]).to eq("John Doo Smith")
        expect(json_response["data"]["user_id"]).to eq(user.id)
      end
    end

    context "with non-existent account number" do
      it "returns not found error" do
        get lookup_by_account_number_virtual_accounts_path, params: { account_number: "NONEXISTENT123" }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        
        expect(json_response["success"]).to be_falsey
        expect(json_response["error"]).to eq("Virtual account not found")
      end
    end

    context "without account number parameter" do
      it "returns bad request error" do
        get lookup_by_account_number_virtual_accounts_path
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response["error"]).to eq("Account number is required")
      end
    end

    context "with empty account number" do
      it "returns bad request error" do
        get lookup_by_account_number_virtual_accounts_path, params: { account_number: "" }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response["error"]).to eq("Account number is required")
      end
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
