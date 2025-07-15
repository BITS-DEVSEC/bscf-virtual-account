class VirtualAccountTransactionsController < ApplicationController
  include Common

  def index
    transactions = Bscf::Core::VirtualAccountTransaction.all
    render json: { success: true, data: transactions }, status: :ok
  end

  def my_transactions
    user_account_ids = Bscf::Core::VirtualAccount.where(user_id: current_user.id).pluck(:id)
    
    transactions = Bscf::Core::VirtualAccountTransaction
                    .where(account_id: user_account_ids)
                    .includes(:account)
                    .order(created_at: :desc)
    
    render json: { success: true, data: transactions }, status: :ok
  end

  def create
    result = VirtualAccountTransactionService.create_transaction(model_params.to_h)
    
    if result.success?
      render json: {
        success: true,
        data: result.transactions
      }, status: :created
    else
      render json: {
        success: false,
        errors: result.errors
      }, status: :unprocessable_entity
    end
  end

  private

  def model_params
    params.require(:payload).permit(permitted_params)
  end

  def permitted_params
    [
      :from_account_id,
      :to_account_id,
      :amount,
      :transaction_type,
      :status,
      :description,
      :reference_number
    ]
  end
end
