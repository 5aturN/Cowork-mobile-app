-- Migration to create transactions table and wallet balance trigger

-- Create transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID NOT NULL PRIMARY KEY,
  user_id UUID NOT NULL,
  amount NUMERIC NOT NULL,
  type TEXT NOT NULL,
  description TEXT,
  booking_id UUID, -- Reference to related booking for payment/refund
  metadata JSONB, -- Additional details (room name, date, slot, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT transactions_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT transactions_type_check CHECK (type IN ('deposit', 'payment', 'refund'))
);

CREATE INDEX IF NOT EXISTS transactions_user_id_idx ON public.transactions (user_id);
CREATE INDEX IF NOT EXISTS transactions_created_at_idx ON public.transactions (created_at DESC);
CREATE INDEX IF NOT EXISTS transactions_type_idx ON public.transactions (type);

COMMENT ON TABLE public.transactions IS 'Транзакции кошелька пользователя';
COMMENT ON COLUMN public.transactions.type IS 'Тип транзакции: deposit (пополнение), payment (оплата), refund (возврат)';

-- Enable RLS for transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view own transactions
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
CREATE POLICY "Users can view own transactions" ON transactions
  FOR SELECT 
  USING (auth.uid() = user_id);

-- RLS Policy: Users can create own transactions
DROP POLICY IF EXISTS "Users can create own transactions" ON transactions;
CREATE POLICY "Users can create own transactions" ON transactions
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Function to automatically update user balance when transaction is created
CREATE OR REPLACE FUNCTION update_user_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user balance by adding the amount
  -- Amount should be positive for deposits/refunds and negative for payments
  UPDATE users 
  SET balance = COALESCE(balance, 0) + NEW.amount
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update balance after transaction insert
DROP TRIGGER IF EXISTS update_balance_on_transaction ON transactions;
CREATE TRIGGER update_balance_on_transaction
  AFTER INSERT ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_balance();

COMMENT ON FUNCTION update_user_balance() IS 'Автоматически обновляет баланс пользователя при создании транзакции';
