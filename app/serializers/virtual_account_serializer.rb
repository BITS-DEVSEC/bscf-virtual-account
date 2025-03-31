class VirtualAccountSerializer < ActiveModel::Serializer
  attributes :id,
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
             :status,
             :created_at,
             :updated_at

  belongs_to :user
end
