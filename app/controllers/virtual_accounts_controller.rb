class VirtualAccountsController < ApplicationController
  include Common

  private

  def model_params
    params.require(:payload).permit(permitted_params)
  end

  def permitted_params
    # Add your permitted params here
    [
      :user_id,
      :account_number,
      :cbs_account_number,
      :balance,
      :interest_rate,
      :interest_type,
      :active,
      :branch_code,
      :product_scheme,
      :voucher_type,
      :status
    ]
  end
end
