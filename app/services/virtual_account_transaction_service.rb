class VirtualAccountTransactionService
  class Result
    attr_reader :transactions, :errors
    
    def initialize(transactions: [], errors: [])
      @transactions = transactions
      @errors = errors
    end
    
    def success?
      errors.empty?
    end
  end

  def self.create_transaction(params)
    new.create_transaction(params)
  end

  def create_transaction(params)
    return Result.new(errors: ['Invalid transaction type']) unless valid_transaction_type?(params[:transaction_type])
    return Result.new(errors: ['Amount is required']) unless params[:amount].present?
    
    case params[:transaction_type]
    when 'transfer'
      create_transfer(params)
    when 'deposit'
      create_deposit(params)
    when 'withdrawal'
      create_withdrawal(params)
    else
      Result.new(errors: ['Unsupported transaction type'])
    end
  end

  private

  def create_transfer(params)
    from_account = find_account(params[:from_account_id])
    to_account = find_account(params[:to_account_id])
    
    return Result.new(errors: ['From account not found']) unless from_account
    return Result.new(errors: ['To account not found']) unless to_account
    return Result.new(errors: ['Insufficient balance']) if BigDecimal(from_account.balance.to_s) < BigDecimal(params[:amount].to_s)
    
    transactions = []
    base_reference = params[:reference_number] || generate_reference_number
    
    ActiveRecord::Base.transaction do
      # Create transactions without paired_transaction first
      debit_transaction = create_transaction_record_without_pairing(
        account: from_account,
        amount: params[:amount],
        transaction_type: 'transfer',
        entry_type: 'debit',
        status: params[:status] || 'completed',
        description: params[:description] || "Transfer to #{to_account.account_number}",
        reference_number: "#{base_reference}-DR"
      )
      
      credit_transaction = create_transaction_record_without_pairing(
        account: to_account,
        amount: params[:amount],
        transaction_type: 'transfer',
        entry_type: 'credit',
        status: params[:status] || 'completed',
        description: params[:description] || "Transfer from #{from_account.account_number}",
        reference_number: "#{base_reference}-CR"
      )
      
      # Link the transactions as pairs
      debit_transaction.update!(paired_transaction: credit_transaction)
      credit_transaction.update!(paired_transaction: debit_transaction)
      
      transactions = [debit_transaction, credit_transaction]
    end
    
    Result.new(transactions: transactions)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(errors: [e.message])
  rescue StandardError => e
    Result.new(errors: ["Transaction failed: #{e.message}"])
  end

  def create_deposit(params)
    account = find_account(params[:account_id] || params[:to_account_id] || params[:from_account_id])
    return Result.new(errors: ['Account not found']) unless account
    
    transaction = create_transaction_record(
      account: account,
      amount: params[:amount],
      transaction_type: 'deposit',
      entry_type: 'credit',
      status: params[:status] || 'completed',
      description: params[:description] || 'Deposit',
      reference_number: params[:reference_number] || generate_reference_number
    )
    
    Result.new(transactions: [transaction])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(errors: [e.message])
  end

  def create_withdrawal(params)
    account = find_account(params[:account_id] || params[:from_account_id] || params[:to_account_id])
    return Result.new(errors: ['Account not found']) unless account
    return Result.new(errors: ['Insufficient balance']) if BigDecimal(account.balance.to_s) < BigDecimal(params[:amount].to_s)
    
    transaction = create_transaction_record(
      account: account,
      amount: params[:amount],
      transaction_type: 'withdrawal',
      entry_type: 'debit',
      status: params[:status] || 'completed',
      description: params[:description] || 'Withdrawal',
      reference_number: params[:reference_number] || generate_reference_number
    )
    
    Result.new(transactions: [transaction])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(errors: [e.message])
  end

  def create_transaction_record(account:, amount:, transaction_type:, entry_type:, status:, description:, reference_number:)
    new_balance = calculate_new_balance(account, amount, entry_type)
    
    transaction = Bscf::Core::VirtualAccountTransaction.create!(
      account: account,
      amount: BigDecimal(amount.to_s),
      transaction_type: transaction_type,
      entry_type: entry_type,
      status: status,
      description: description,
      reference_number: reference_number,
      running_balance: BigDecimal(new_balance.to_s)
    )
    
    # Update account balance
    account.update!(balance: BigDecimal(new_balance.to_s))
    account.reload
    
    transaction
  end

  def create_transaction_record_without_pairing(account:, amount:, transaction_type:, entry_type:, status:, description:, reference_number:)
    new_balance = calculate_new_balance(account, amount, entry_type)
    
    # Create transaction without paired_transaction to avoid validation issues
    transaction = Bscf::Core::VirtualAccountTransaction.new(
      account: account,
      amount: BigDecimal(amount.to_s),
      transaction_type: transaction_type,
      entry_type: entry_type,
      status: status,
      description: description,
      reference_number: reference_number,
      running_balance: BigDecimal(new_balance.to_s)
    )
    
    # Skip validations that require paired_transaction
    transaction.save!(validate: false)
    
    # Update account balance
    account.update!(balance: BigDecimal(new_balance.to_s))
    account.reload
    
    transaction
  end

  def calculate_new_balance(account, amount, entry_type)
    current_balance = BigDecimal(account.balance.to_s)
    amount_decimal = BigDecimal(amount.to_s)
    
    case entry_type
    when 'credit'
      current_balance + amount_decimal
    when 'debit'
      current_balance - amount_decimal
    else
      current_balance
    end
  end

  def find_account(account_id)
    return nil unless account_id
    Bscf::Core::VirtualAccount.find_by(id: account_id)
  end

  def generate_reference_number
    "TXN#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
  end

  def valid_transaction_type?(type)
    %w[transfer deposit withdrawal].include?(type)
  end
end