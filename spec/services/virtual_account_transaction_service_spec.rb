require 'rails_helper'

RSpec.describe VirtualAccountTransactionService, type: :service do
  let(:from_account) { create(:virtual_account, :active, balance: 1000.00) }
  let(:to_account) { create(:virtual_account, :active, balance: 500.00) }
  
  describe '.create_transaction' do
    context 'with transfer transaction' do
      let(:transfer_params) do
        {
          from_account_id: from_account.id,
          to_account_id: to_account.id,
          amount: 200.00,
          transaction_type: 'transfer',
          description: 'Test transfer'
        }
      end
      
      it 'creates two linked transactions' do
        result = described_class.create_transaction(transfer_params)
        
        expect(result.success?).to be true
        expect(result.transactions.count).to eq(2)
        
        debit_transaction = result.transactions.find(&:debit?)
        credit_transaction = result.transactions.find(&:credit?)
        
        expect(debit_transaction.account).to eq(from_account)
        expect(debit_transaction.amount).to eq(200.00)
        expect(debit_transaction.paired_transaction).to eq(credit_transaction)
        
        expect(credit_transaction.account).to eq(to_account)
        expect(credit_transaction.amount).to eq(200.00)
        expect(credit_transaction.paired_transaction).to eq(debit_transaction)
      end
      
      it 'updates account balances correctly' do
        described_class.create_transaction(transfer_params)
        
        from_account.reload
        to_account.reload
        
        expect(from_account.balance).to eq(800.00)
        expect(to_account.balance).to eq(700.00)
      end
      
      it 'sets correct running balances' do
        result = described_class.create_transaction(transfer_params)
        
        debit_transaction = result.transactions.find(&:debit?)
        credit_transaction = result.transactions.find(&:credit?)
        
        expect(debit_transaction.running_balance).to eq(800.00)
        expect(credit_transaction.running_balance).to eq(700.00)
      end
    end
    
    context 'with deposit transaction' do
      let(:deposit_params) do
        {
          account_id: from_account.id,
          amount: 300.00,
          transaction_type: 'deposit',
          description: 'Test deposit'
        }
      end
      
      it 'creates a single credit transaction' do
        result = described_class.create_transaction(deposit_params)
        
        expect(result.success?).to be true
        expect(result.transactions.count).to eq(1)
        
        transaction = result.transactions.first
        expect(transaction.credit?).to be true
        expect(transaction.account).to eq(from_account)
        expect(transaction.amount).to eq(300.00)
        expect(transaction.paired_transaction).to be_nil
      end
      
      it 'increases account balance' do
        described_class.create_transaction(deposit_params)
        
        from_account.reload
        expect(from_account.balance).to eq(1300.00)
      end
    end
    
    context 'with withdrawal transaction' do
      let(:withdrawal_params) do
        {
          account_id: from_account.id,
          amount: 150.00,
          transaction_type: 'withdrawal',
          description: 'Test withdrawal'
        }
      end
      
      it 'creates a single debit transaction' do
        result = described_class.create_transaction(withdrawal_params)
        
        expect(result.success?).to be true
        expect(result.transactions.count).to eq(1)
        
        transaction = result.transactions.first
        expect(transaction.debit?).to be true
        expect(transaction.account).to eq(from_account)
        expect(transaction.amount).to eq(150.00)
        expect(transaction.paired_transaction).to be_nil
      end
      
      it 'decreases account balance' do
        described_class.create_transaction(withdrawal_params)
        
        from_account.reload
        expect(from_account.balance).to eq(850.00)
      end
      
      context 'with insufficient balance' do
        let(:large_withdrawal_params) do
          {
            account_id: from_account.id,
            amount: 1500.00,
            transaction_type: 'withdrawal',
            description: 'Large withdrawal'
          }
        end
        
        it 'returns error for insufficient balance' do
          result = described_class.create_transaction(large_withdrawal_params)
          
          expect(result.success?).to be false
          expect(result.errors).to include('Insufficient balance')
        end
      end
    end
    
    context 'with invalid parameters' do
      it 'returns error for invalid transaction type' do
        invalid_params = {
          account_id: from_account.id,
          amount: 100.00,
          transaction_type: 'invalid_type'
        }
        
        result = described_class.create_transaction(invalid_params)
        
        expect(result.success?).to be false
        expect(result.errors).to include('Invalid transaction type')
      end
      
      it 'returns error for missing amount' do
        invalid_params = {
          account_id: from_account.id,
          transaction_type: 'deposit'
        }
        
        result = described_class.create_transaction(invalid_params)
        
        expect(result.success?).to be false
        expect(result.errors).to be_present
      end
      
      it 'returns error for non-existent account' do
        invalid_params = {
          account_id: 99999,
          amount: 100.00,
          transaction_type: 'deposit'
        }
        
        result = described_class.create_transaction(invalid_params)
        
        expect(result.success?).to be false
        expect(result.errors).to include('Account not found')
      end
    end
    
    context 'transaction atomicity' do
      it 'rolls back all changes if any transaction fails' do
        # Create a scenario that will cause a failure during transaction processing
        # by trying to transfer more than available balance
        transfer_params = {
          from_account_id: from_account.id,
          to_account_id: to_account.id,
          amount: 1500.00, # More than the 1000.00 balance
          transaction_type: 'transfer'
        }
        
        result = described_class.create_transaction(transfer_params)
        
        # Should fail due to insufficient balance
        expect(result.success?).to be false
        expect(result.errors).to include('Insufficient balance')
        
        # No transactions should be created
        expect(result.transactions.count).to eq(0)
        
        # Account balances should remain unchanged
        from_account.reload
        to_account.reload
        expect(from_account.balance).to eq(1000.00)
        expect(to_account.balance).to eq(500.00)
      end
    end
  end
end