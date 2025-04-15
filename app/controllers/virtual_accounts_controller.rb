class VirtualAccountsController < ApplicationController
  include Common

  def verified_accounts
    @virtual_accounts = Bscf::Core::VirtualAccount.where(status: :active)
    render json: @virtual_accounts
  end

  private

  def model_params
    params.require(:payload).permit(permitted_params)
  end

  def permitted_params
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
