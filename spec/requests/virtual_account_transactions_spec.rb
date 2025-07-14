require "rails_helper"

RSpec.describe "VirtualAccountTransactions", type: :request do
  let(:from_account) { create(:virtual_account, :active, balance: 10000.00) }
  let(:to_account) { create(:virtual_account, :active, balance: 5000.00) }

  let(:valid_transfer_attributes) do
    {
      from_account_id: from_account.id,
      to_account_id: to_account.id,
      amount: 500.00,
      transaction_type: "transfer",
      status: "completed",
      description: "Test transfer"
    }
  end

  let(:valid_deposit_attributes) do
    {
      to_account_id: to_account.id,
      amount: 1000.00,
      transaction_type: "deposit",
      status: "completed",
      description: "Test deposit"
    }
  end

  let(:invalid_attributes) do
    {
      from_account_id: nil,
      to_account_id: nil,
      amount: nil,
      transaction_type: "invalid"
    }
  end

  describe "POST /virtual_account_transactions" do
    context "with valid transfer attributes" do
      it "creates two linked transactions (debit and credit)" do
        
        expect {
          post virtual_account_transactions_path, 
               params: { payload: valid_transfer_attributes }, 
               as: :json
        }.to change(Bscf::Core::VirtualAccountTransaction, :count).by(2)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be_truthy
        expect(json_response["data"]).to be_an(Array)
        expect(json_response["data"].length).to eq(2)
      end
    end

    context "with valid deposit attributes" do
      it "creates a single credit transaction" do
        expect {
          post virtual_account_transactions_path, 
               params: { payload: valid_deposit_attributes }, 
               as: :json
        }.to change(Bscf::Core::VirtualAccountTransaction, :count).by(1)
        
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid attributes" do
      it "returns validation errors" do
        post virtual_account_transactions_path, 
             params: { payload: invalid_attributes }, 
             as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be_falsey
        expect(json_response["errors"]).to be_present
      end
    end
  end
end
