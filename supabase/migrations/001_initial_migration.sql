-- Миграция базы данных Supabase для мобильного приложения Secretaire
-- Эта миграция добавляет новые поля к существующим таблицам без потери данных

-- ================================================
-- 1. Улучшения существующих таблиц
-- ================================================

-- Users: добавляем поля для мобильного приложения
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true;

COMMENT ON COLUMN public.users.avatar_url IS 'URL аватара пользователя';
COMMENT ON COLUMN public.users.updated_at IS 'Дата последнего обновления профиля';
COMMENT ON COLUMN public.users.notifications_enabled IS 'Включены ли push-уведомления';

-- Spaces: добавляем информацию о локации
ALTER TABLE public.spaces 
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS working_hours JSONB,
  ADD COLUMN IF NOT EXISTS amenities TEXT[];

COMMENT ON COLUMN public.spaces.address IS 'Физический адрес пространства';
COMMENT ON COLUMN public.spaces.working_hours IS 'Часы работы в формате JSON';
COMMENT ON COLUMN public.spaces.amenities IS 'Общие удобства (Wi-Fi, кофе и т.д.)';

-- Rooms: расширяем информацию о кабинетах
ALTER TABLE public.rooms 
  ADD COLUMN IF NOT EXISTS area NUMERIC,
  ADD COLUMN IF NOT EXISTS amenities TEXT[],
  ADD COLUMN IF NOT EXISTS rating NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

COMMENT ON COLUMN public.rooms.area IS 'Площадь кабинета в квадратных метрах';
COMMENT ON COLUMN public.rooms.amenities IS 'Удобства кабинета (Кресла, Кушетка, С окном)';
COMMENT ON COLUMN public.rooms.rating IS 'Средний рейтинг на основе отзывов';
COMMENT ON COLUMN public.rooms.is_available IS 'Доступен ли кабинет для бронирования';

-- Миграция фотографий: переход с одного фото на массив
ALTER TABLE public.rooms ADD COLUMN IF NOT EXISTS photos TEXT[];
UPDATE public.rooms SET photos = ARRAY[photo_path] WHERE photo_path IS NOT NULL AND photos IS NULL;

COMMENT ON COLUMN public.rooms.photos IS 'Массив URL фотографий кабинета';
-- После проверки миграции можно удалить старую колонку:
-- ALTER TABLE public.rooms DROP COLUMN IF EXISTS photo_path;

-- Bookings: добавляем сумму бронирования
ALTER TABLE public.bookings 
  ADD COLUMN IF NOT EXISTS amount NUMERIC,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

COMMENT ON COLUMN public.bookings.amount IS 'Сумма бронирования';
COMMENT ON COLUMN public.bookings.updated_at IS 'Дата последнего обновления бронирования';

-- Добавляем constraint на статусы бронирования (если его еще нет)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'bookings_status_check'
  ) THEN
    ALTER TABLE public.bookings 
      ADD CONSTRAINT bookings_status_check 
      CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed'));
  END IF;
END $$;

-- Orders: добавляем способ оплаты
ALTER TABLE public.orders 
  ADD COLUMN IF NOT EXISTS payment_method TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

COMMENT ON COLUMN public.orders.payment_method IS 'Способ оплаты (card, cash, balance)';

-- Добавляем constraint на статусы заказов
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'orders_status_check'
  ) THEN
    ALTER TABLE public.orders 
      ADD CONSTRAINT orders_status_check 
      CHECK (status IN ('pending', 'paid', 'failed', 'refunded'));
  END IF;
END $$;

-- ================================================
-- 2. Создание новых таблиц
-- ================================================

-- Long Terms: долгосрочная аренда (если таблица не существует)
CREATE TABLE IF NOT EXISTS public.long_terms (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  room_id UUID NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  total_amount NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT long_terms_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT long_terms_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
  CONSTRAINT long_terms_status_check CHECK (status IN ('active', 'expired', 'cancelled')),
  CONSTRAINT long_terms_dates_check CHECK (end_date > start_date)
);

CREATE INDEX IF NOT EXISTS long_terms_user_id_idx ON public.long_terms (user_id);
CREATE INDEX IF NOT EXISTS long_terms_room_id_idx ON public.long_terms (room_id);
CREATE INDEX IF NOT EXISTS long_terms_status_idx ON public.long_terms (status);

COMMENT ON TABLE public.long_terms IS 'Долгосрочная аренда кабинетов';

-- Reviews: отзывы о кабинетах
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  room_id UUID NOT NULL,
  booking_id UUID NOT NULL,
  rating INTEGER NOT NULL,
  comment TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT reviews_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
  CONSTRAINT reviews_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
  CONSTRAINT reviews_rating_check CHECK (rating >= 1 AND rating <= 5),
  CONSTRAINT reviews_unique_booking UNIQUE (booking_id)
);

CREATE INDEX IF NOT EXISTS reviews_user_id_idx ON public.reviews (user_id);
CREATE INDEX IF NOT EXISTS reviews_room_id_idx ON public.reviews (room_id);
CREATE INDEX IF NOT EXISTS reviews_rating_idx ON public.reviews (rating);

COMMENT ON TABLE public.reviews IS 'Отзывы пользователей о кабинетах';
COMMENT ON COLUMN public.reviews.rating IS 'Рейтинг от 1 до 5';

-- Notifications: уведомления пользователей
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  related_booking_id UUID NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT notifications_booking_id_fkey FOREIGN KEY (related_booking_id) REFERENCES bookings (id) ON DELETE SET NULL,
  CONSTRAINT notifications_type_check CHECK (type IN ('booking', 'payment', 'reminder', 'system'))
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS notifications_is_read_idx ON public.notifications (is_read);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.notifications (created_at DESC);

COMMENT ON TABLE public.notifications IS 'Push-уведомления для пользователей';
COMMENT ON COLUMN public.notifications.type IS 'Тип уведомления: booking, payment, reminder, system';

-- ================================================
-- 3. Функции и триггеры
-- ================================================

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггеры для автообновления updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_rooms_updated_at ON rooms;
CREATE TRIGGER update_rooms_updated_at 
  BEFORE UPDATE ON rooms
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_bookings_updated_at ON bookings;
CREATE TRIGGER update_bookings_updated_at 
  BEFORE UPDATE ON bookings
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at 
  BEFORE UPDATE ON orders
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_long_terms_updated_at ON long_terms;
CREATE TRIGGER update_long_terms_updated_at 
  BEFORE UPDATE ON long_terms
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reviews_updated_at ON reviews;
CREATE TRIGGER update_reviews_updated_at 
  BEFORE UPDATE ON reviews
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Функция для автоматического обновления рейтинга кабинета
CREATE OR REPLACE FUNCTION update_room_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE rooms
  SET rating = (
    SELECT COALESCE(AVG(rating), 0)
    FROM reviews
    WHERE room_id = NEW.room_id
  )
  WHERE id = NEW.room_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для обновления рейтинга при добавлении/обновлении отзыва
DROP TRIGGER IF EXISTS update_room_rating_on_review ON reviews;
CREATE TRIGGER update_room_rating_on_review
  AFTER INSERT OR UPDATE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_room_rating();

-- ================================================
-- 4. Row Level Security (RLS)
-- ================================================

-- Включить RLS для всех пользовательских таблиц
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE long_terms ENABLE ROW LEVEL SECURITY;

-- Spaces и Rooms доступны всем для чтения
ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users
DROP POLICY IF EXISTS "Users can view own data" ON users;
CREATE POLICY "Users can view own data" ON users
  FOR SELECT 
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON users;
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE 
  USING (auth.uid() = id);

-- RLS Policies: Bookings
DROP POLICY IF EXISTS "Users can view own bookings" ON bookings;
CREATE POLICY "Users can view own bookings" ON bookings
  FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create bookings" ON bookings;
CREATE POLICY "Users can create bookings" ON bookings
  FOR INSERT  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
CREATE POLICY "Users can update own bookings" ON bookings
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- RLS Policies: Spaces (все могут читать)
DROP POLICY IF EXISTS "Everyone can view spaces" ON spaces;
CREATE POLICY "Everyone can view spaces" ON spaces
  FOR SELECT 
  USING (true);

-- RLS Policies: Rooms (все могут читать)
DROP POLICY IF EXISTS "Everyone can view rooms" ON rooms;
CREATE POLICY "Everyone can view rooms" ON rooms
  FOR SELECT 
  USING (true);

-- RLS Policies: Reviews
DROP POLICY IF EXISTS "Users can view all reviews" ON reviews;
CREATE POLICY "Users can view all reviews" ON reviews
  FOR SELECT 
  USING (true);

DROP POLICY IF EXISTS "Users can create own reviews" ON reviews;
CREATE POLICY "Users can create own reviews" ON reviews
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
CREATE POLICY "Users can update own reviews" ON reviews
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- RLS Policies: Notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- RLS Policies: Orders
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT 
  USING (auth.uid() = user_id);

-- RLS Policies: Long Terms
DROP POLICY IF EXISTS "Users can view own long terms" ON long_terms;
CREATE POLICY "Users can view own long terms" ON long_terms
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Admin Policies: Администраторы видят всё
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
CREATE POLICY "Admins can view all bookings" ON bookings
  FOR SELECT 
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND isadmin = true)
  );

DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
CREATE POLICY "Admins can view all orders" ON orders
  FOR SELECT 
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND isadmin = true)
  );

DROP POLICY IF EXISTS "Admins can manage rooms" ON rooms;
CREATE POLICY "Admins can manage rooms" ON rooms
  FOR ALL 
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND isadmin = true)
  );

DROP POLICY IF EXISTS "Admins can manage spaces" ON spaces;
CREATE POLICY "Admins can manage spaces" ON spaces
  FOR ALL 
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND isadmin = true)
  );

-- ================================================
-- 5. Комментарии и документация
-- ================================================

COMMENT ON TABLE public.users IS 'Пользователи системы (психологи и администраторы)';
COMMENT ON TABLE public.spaces IS 'Физические пространства/локации с кабинетами';
COMMENT ON TABLE public.rooms IS 'Кабинеты для консультаций';
COMMENT ON TABLE public.bookings IS 'Бронирования кабинетов';
COMMENT ON TABLE public.orders IS 'Заказы и платежи';

-- Готово! Миграция завершена.
