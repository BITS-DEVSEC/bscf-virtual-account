module Ransackable
  extend ActiveSupport::Concern

  class_methods do
    private

    def common_attributes
      %w[id created_at updated_at]
    end

    def base_namespace
      "Bscf::Core::"
    end

    def model_attributes_mapping
      @model_attributes_mapping ||= {
        "VirtualAccount" => {
          attributes: %w[account_number balance status user_id currency],
          associations: %w[user transactions]
        },
        "Transaction" => {
          attributes: %w[amount transaction_type reference_number status description virtual_account_id],
          associations: %w[virtual_account]
        },
        "User" => {
          attributes: %w[email name phone_number status],
          associations: %w[virtual_accounts]
        }
      }.freeze
    end

    def model_key
      self.name.delete_prefix(base_namespace)
    end

    def model_config
      model_attributes_mapping[model_key] || { attributes: [], associations: [] }
    end

    public

    def ransackable_attributes(auth_object = nil)
      attributes = common_attributes + model_config[:attributes]
      Set.new(attributes).freeze & column_names
    end

    def ransackable_associations(auth_object = nil)
      associations = model_config[:associations]
      Set.new(associations).freeze & reflect_on_all_associations.map(&:name).map(&:to_s)
    end

    def ransackable_scopes(auth_object = nil)
      []
    end
  end
end
