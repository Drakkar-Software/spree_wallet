require 'spec_helper'
require File.join( File.dirname(__FILE__), 'shared_examples/disable_negative_payment_mode_ability_spec')


describe Spree::Credit, type: :model do
  let(:user) { Spree::User.create!(:email => 'abc@test.com', :password => '123456') }
  let(:credit) { Spree::Credit.new(:amount => 123, :reason => 'test reason', :payment_mode => 0) { |credit| credit.user = user }}

  describe 'constants' do
    describe 'PAYMENT_MODE' do
      it { expect(Spree::Credit::PAYMENT_MODE).to eq({ 'Payment Refund' => -1, 'Refund' => 0, 'Bank' => 1 })}
    end
  end

  it_should_behave_like 'disable_negative_payment_mode', Spree::Credit

  describe 'set_balance' do
    let(:store_credits_total) { 1000 }
    before(:each) do
      user.store_credits_total = store_credits_total
    end

    context 'on create' do
      shared_examples_for 'cannot_set_balance' do
        it 'should not update balance' do
          credit.save
          expect(credit.balance).not_to eq(store_credits_total + credit.amount.to_f)
        end

        it 'should not recieve effective_amount' do
          expect(credit).not_to receive(:effective_amount)
          credit.save
        end

        it 'should receive set_balance' do
          expect(credit).to receive(:set_balance).and_call_original
          credit.save
        end
      end
      
      context 'when there is no user' do
        before(:each) do
          credit.user = nil
        end

        it_should_behave_like 'cannot_set_balance'
      end

      context 'when there is user' do
        context 'when there is no amount' do
          before(:each) do
            credit.amount = nil
          end

          it_should_behave_like 'cannot_set_balance'
        end

        context 'when there is amount' do
          it 'should update balance' do
            credit.save!
            expect(credit.balance).to eq(store_credits_total + credit.amount)
          end

          it 'should recieve effective_amount' do
            expect(credit).to receive(:effective_amount).and_return(credit.amount)
            credit.save
          end

          describe 'effective_amount' do
            context 'when it has no arguement' do
              it 'should return the amount' do
                expect(credit.send(:effective_amount)).to eq(credit.amount)
              end
            end

            context 'when it has arguement' do
              it 'should return the value' do
                expect(credit.send(:effective_amount, 1000)).to eq(1000)
              end
            end
          end

          it 'should receive set_balance' do
            expect(credit).to receive(:set_balance).and_call_original
            credit.save!
          end
        end
      end
    end

    context 'on update' do
      before(:each) do
        credit.save!
        credit.reason = 'testing reason'
      end

      it 'should not update balance' do
        credit.save!
        expect(credit.balance).not_to eq(user.store_credits_total + credit.amount)
      end

      it 'should not receive set_balance' do
        expect(credit).not_to receive(:set_balance)
        credit.save!
      end
    end
  end
end
