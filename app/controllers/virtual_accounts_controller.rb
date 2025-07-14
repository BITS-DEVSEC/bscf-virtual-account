class VirtualAccountsController < ApplicationController
  include Common
  before_action :is_authenticated

  def my_virtual_accounts
    virtual_accounts = Bscf::Core::VirtualAccount.where(user_id: current_user.id)
    render json: virtual_accounts, status: :ok
  end

  def verified_accounts
    virtual_accounts = Bscf::Core::VirtualAccount.where(status: :active)
    render json: virtual_accounts, status: :ok
  end

  def approve
    virtual_account = Bscf::Core::VirtualAccount.find(params[:id])
    
    if virtual_account.pending? && virtual_account.update(status: :active)
      render json: virtual_account, status: :ok
    else
      render json: { errors: virtual_account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def suspend
    virtual_account = Bscf::Core::VirtualAccount.find(params[:id])
    
    if virtual_account.pending? && virtual_account.update(status: :suspended)
      render json: virtual_account, status: :ok
    else
      render json: { errors: virtual_account.errors.full_messages }, status: :unprocessable_entity
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
