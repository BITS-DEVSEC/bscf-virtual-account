class VirtualAccountTransactionsController < ApplicationController
  include Common

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
