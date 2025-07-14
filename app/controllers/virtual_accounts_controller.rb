class VirtualAccountsController < ApplicationController
  include Common

  def my_virtual_accounts
    virtual_accounts = Bscf::Core::VirtualAccount.where(user_id: current_user.id)
    render json: virtual_accounts, status: :ok
  end

  def verified_accounts
    virtual_accounts = Bscf::Core::VirtualAccount.where(status: :active)
    render json: virtual_accounts, status: :ok
  end

  def lookup_by_account_number
    unless params[:account_number].present?
      render json: { error: "Account number is required" }, status: :bad_request
      return
    end

    virtual_account = Bscf::Core::VirtualAccount.includes(:user)
                                                .find_by(account_number: params[:account_number])
    
    if virtual_account
      user = virtual_account.user
      account_holder_name = "#{user.first_name} #{user.middle_name} #{user.last_name}".strip
      
      render json: {
        success: true,
        data: {
          account_id: virtual_account.id,
          account_number: virtual_account.account_number,
          account_holder_name: account_holder_name,
          user_id: user.id
        }
      }, status: :ok
    else
      render json: { 
        success: false, 
        error: "Virtual account not found" 
      }, status: :not_found
    end
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
