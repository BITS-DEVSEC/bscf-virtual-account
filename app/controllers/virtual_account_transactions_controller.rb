class VirtualAccountTransactionsController < ApplicationController
  include Common

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
      :description
    ]
  end
end
