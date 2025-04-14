class VirtualAccountsController < ApplicationController
  include Common

  def verified_accounts
    @virtual_accounts = Bscf::Core::VirtualAccount.where(status: :verified)
    render json: @virtual_accounts
  end

  def update_kyc_status
    @virtual_account = Bscf::Core::VirtualAccount.find(params[:id])
    
    if @virtual_account.update(status: params[:status])
      render json: @virtual_account
    else
      render json: { errors: @virtual_account.errors }, status: :unprocessable_entity
    end
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
