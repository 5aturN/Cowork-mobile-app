# Cowork-monile-app - Система бронирования кабинетов

Мобильное приложение для бронирования кабинетов для профессиональных консультаций.

## 🚀 Технологический стек

- **Framework**: Flutter 3.2+
- **State Management**: Riverpod с кодогенерацией
- **Navigation**: GoRouter
- **Backend**: Supabase (PostgreSQL + Auth)
- **Architecture**: Feature-first architecture

## 📁 Структура проекта

```
lib/
├── core/                    # Основная инфраструктура
│   ├── constants/          # Константы и строки локализации
│   ├── router/             # Навигация (GoRouter)
│   └── theme/              # Темы, цвета, типографика
├── features/               # Фичи приложения
│   ├── welcome/           # Экран приветствия
│   ├── auth/              # Авторизация
│   ├── booking/           # Бронирование
│   └── profile/           # Профиль
└── shared/                # Переиспользуемые компоненты
    └── widgets/           # UI виджеты
```

## 🎨 Дизайн

Дизайн создан в Stitch и находится в папке `StitchAssets/`.

### Цвета
- Primary: `#13C8EC` (голубой)
- Background Dark: `#101F22`
- Background Light: `#F6F8F8`

### Шрифт
- **Manrope** (Google Fonts)

## 🛠️ Установка и запуск

### Требования
- Flutter SDK 3.2 или выше
- Dart 3.0 или выше

### Установка зависимостей

```bash
flutter pub get
```

### Генерация кода (Riverpod, Freezed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Запуск приложения

```bash
flutter run
```

### 📱 Запуск на Android устройстве

#### 1. Включите режим разработчика на телефоне

**На большинстве Android устройств:**
1. Откройте **Настройки** → **О телефоне**
2. Найдите **Номер сборки** (может быть в разделе "Сведения о ПО")
3. Нажмите на него **7 раз** подряд
4. Появится сообщение "Вы стали разработчиком!"

#### 2. Включите отладку по USB

1. Откройте **Настройки** → **Для разработчиков** (или **Параметры разработчика**)
2. Включите **Отладку по USB**
3. (Опционально) Включите **Установку через USB**

#### 3. Подключите телефон к компьютеру

1. Подключите телефон к ПК через USB-кабель
2. На телефоне появится запрос "Разрешить отладку по USB?" - нажмите **ОК**
3. Выберите режим подключения **Передача файлов (MTP)** или **Без передачи данных**

#### 4. Проверьте подключение

```bash
flutter devices
```

Вы должны увидеть что-то вроде:
```
Found 2 connected devices:
  SM G960F (mobile) • 988a1d474e4b4e4641 • android-arm64 • Android 10 (API 29)
  Chrome (web)      • chrome              • web-javascript • Google Chrome
```

#### 5. Запустите приложение

```bash
flutter run
```

Или выберите конкретное устройство:
```bash
flutter run -d <device-id>
```

#### 6. Hot Reload во время разработки

После запуска приложения:
- Нажмите **`r`** в терминале для hot reload (быстрая перезагрузка)
- Нажмите **`R`** для hot restart (полная перезагрузка)
- Нажмите **`q`** для выхода

### 🔧 Решение проблем Android

**Устройство не определяется:**
1. Убедитесь, что USB-кабель поддерживает передачу данных (не только зарядку)
2. Попробуйте другой USB-порт
3. Установите драйверы для вашего устройства (обычно устанавливаются автоматически)
4. Попробуйте команду: `adb devices` - должен показать ваше устройство

**"No connected devices":**
```bash
adb kill-server
adb start-server
flutter devices
```

**Ошибка подписи приложения:**
- При первой установке это нормально
- Приложение установится в debug режиме

## 📦 Основные зависимости

- `flutter_riverpod` - State management
- `riverpod_annotation` - Кодогенерация для Riverpod
- `go_router` - Навигация
- `supabase_flutter` - Backend интеграция
- `google_fonts` - Шрифт Manrope
- `freezed` - Иммутабельные модели данных

## 🏗️ Архитектура

Проект использует **Feature-first architecture**:

- `domain/` - Бизнес-логика (entities, use cases)
- `data/` - Работа с данными (repositories, data sources)
- `presentation/` - UI слой (pages, widgets, providers)

## 📱 Экраны

1. ✅ **Экран приветствия** - Onboarding с hero изображением
2. ✅ **Вход/Регистрация** - Авторизация через Supabase
3. ✅ **Бронирование кабинетов** - Основной функционал
4. ✅ **Мои бронирования** - История бронирований
5. ✅ **Записи сессий** - Записи прошедших сессий
6. ✅ **Личный кабинет** - Профиль пользователя

## 🌐 Локализация

Приложение поддерживает **русский язык**. Все строки вынесены в `lib/core/constants/app_strings.dart`.

## 🗄️ Структура базы данных Supabase

### Существующие таблицы (совместимость с PWA)

#### 1. `users` - Пользователи

```sql
CREATE TABLE public.users (
  id UUID NOT NULL DEFAULT auth.uid() PRIMARY KEY,
  name TEXT NULL,
  phone TEXT NULL,
  isadmin BOOLEAN NOT NULL DEFAULT false,
  notes TEXT NULL,
  email TEXT NULL,
  telegram_id BIGINT NULL UNIQUE,
  username TEXT NULL,
  balance NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT users_phone_key UNIQUE (phone),
  CONSTRAINT users_telegram_id_key UNIQUE (telegram_id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id)
);
```

**Рекомендации для мобильного приложения:**
- ✅ Оставить без изменений для обратной совместимости
- ➕ Добавить: `avatar_url TEXT` - URL фото профиля
- ➕ Добавить: `updated_at TIMESTAMP WITH TIME ZONE` - дата обновления
- ➕ Добавить: `notifications_enabled BOOLEAN DEFAULT true` - настройки уведомлений

---

#### 2. `spaces` - Пространства/Локации

```sql
CREATE TABLE public.spaces (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NULL,
  photo_path TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Рекомендации:**
- ✅ Оставить без изменений
- ➕ Добавить: `address TEXT` - адрес локации
- ➕ Добавить: `working_hours JSONB` - часы работы
- ➕ Добавить: `amenities TEXT[]` - общие удобства (Wi-Fi, кофе и т.д.)

---

#### 3. `rooms` - Кабинеты

```sql
CREATE TABLE public.rooms (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  space_id UUID NOT NULL DEFAULT gen_random_uuid(),
  photo_path TEXT NULL,
  description TEXT NULL,
  price NUMERIC NOT NULL DEFAULT 0,
  capacity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT rooms_pkey PRIMARY KEY (id),
  CONSTRAINT rooms_space_id_fkey FOREIGN KEY (space_id) REFERENCES spaces (id),
  CONSTRAINT rooms_capacity_check CHECK (capacity >= 1)
);
```

**Рекомендации:**
- ✅ Оставить структуру
- ➕ Добавить: `area NUMERIC` - площадь в м²
- ➕ Добавить: `amenities TEXT[]` - удобства кабинета ['Кресла', 'Кушетка', 'С окном']
- ➕ Добавить: `rating NUMERIC DEFAULT 0` - средний рейтинг
- ➕ Добавить: `is_available BOOLEAN DEFAULT true` - доступность
- 📝 Переименовать: `photo_path` → `photos TEXT[]` - массив URL фотографий

---

#### 4. `bookings` - Бронирования

```sql
CREATE TABLE public.bookings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL DEFAULT gen_random_uuid(),
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NULL,
  payment_id TEXT NULL,
  booking_type TEXT NULL,
  long_term_id UUID NULL,
  comment TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT bookings_pkey PRIMARY KEY (id),
  CONSTRAINT bookings_long_term_id_fkey FOREIGN KEY (long_term_id) REFERENCES long_terms (id) ON DELETE SET NULL,
  CONSTRAINT bookings_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms (id),
  CONSTRAINT bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS bookings_long_term_id_idx ON public.bookings USING btree (long_term_id);
```

**Рекомендации:**
- ✅ Основная структура отличная!
- ➕ Добавить: `amount NUMERIC` - сумма бронирования
- ➕ Добавить: `updated_at TIMESTAMP WITH TIME ZONE` - дата обновления
- 📝 Добавить constraint на статусы:
  ```sql
  CONSTRAINT bookings_status_check 
  CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed'))
  ```

---

#### 5. `orders` - Заказы/Платежи

```sql
CREATE TABLE public.orders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id TEXT NOT NULL,
  user_id UUID NOT NULL,
  payment_id TEXT NULL,
  amount NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'::text,
  items JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NULL DEFAULT now(),
  order_type TEXT NOT NULL DEFAULT 'single'::text,
  long_term_id UUID NULL,
  total_amount NUMERIC NULL,
  
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_long_term_id_fkey FOREIGN KEY (long_term_id) REFERENCES long_terms (id) ON DELETE SET NULL,
  CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS orders_long_term_id_idx ON public.orders USING btree (long_term_id);
```

**Рекомендации:**
- ➕ Добавить: `payment_method TEXT` - способ оплаты (card, cash, balance)
- ➕ Добавить: `updated_at TIMESTAMP WITH TIME ZONE`
- 📝 Добавить constraint:
  ```sql
  CONSTRAINT orders_status_check 
  CHECK (status IN ('pending', 'paid', 'failed', 'refunded'))
  ```

---

### Необходимые дополнительные таблицы

#### 6. `long_terms` - Долгосрочная аренда

```sql
CREATE TABLE public.long_terms (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  room_id UUID NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  total_amount NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT long_terms_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT long_terms_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms (id),
  CONSTRAINT long_terms_status_check CHECK (status IN ('active', 'expired', 'cancelled'))
);
```

---

#### 7. `reviews` - Отзывы (новая таблица для мобильного приложения)

```sql
CREATE TABLE public.reviews (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  room_id UUID NOT NULL,
  booking_id UUID NOT NULL,
  rating INTEGER NOT NULL,
  comment TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT reviews_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms (id),
  CONSTRAINT reviews_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings (id),
  CONSTRAINT reviews_rating_check CHECK (rating >= 1 AND rating <= 5),
  CONSTRAINT reviews_unique_booking UNIQUE (booking_id)
);
```

---

#### 8. `notifications` - Уведомления (новая таблица)

```sql
CREATE TABLE public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  related_booking_id UUID NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT notifications_booking_id_fkey FOREIGN KEY (related_booking_id) REFERENCES bookings (id) ON DELETE SET NULL,
  CONSTRAINT notifications_type_check CHECK (type IN ('booking', 'payment', 'reminder', 'system'))
);

CREATE INDEX notifications_user_id_idx ON public.notifications USING btree (user_id);
CREATE INDEX notifications_is_read_idx ON public.notifications USING btree (is_read);
```

---

### SQL Миграция для улучшений

```sql
-- Миграция существующих таблиц для мобильного приложения

-- Users
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true;

-- Spaces
ALTER TABLE public.spaces 
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS working_hours JSONB,
  ADD COLUMN IF NOT EXISTS amenities TEXT[];

-- Rooms
ALTER TABLE public.rooms 
  ADD COLUMN IF NOT EXISTS area NUMERIC,
  ADD COLUMN IF NOT EXISTS amenities TEXT[],
  ADD COLUMN IF NOT EXISTS rating NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Обновить photo_path на массив (миграция данных)
ALTER TABLE public.rooms ADD COLUMN IF NOT EXISTS photos TEXT[];
UPDATE public.rooms SET photos = ARRAY[photo_path] WHERE photo_path IS NOT NULL;
-- После проверки можно удалить: ALTER TABLE public.rooms DROP COLUMN photo_path;

-- Bookings
ALTER TABLE public.bookings 
  ADD COLUMN IF NOT EXISTS amount NUMERIC,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.bookings 
  ADD CONSTRAINT bookings_status_check 
  CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed'));

-- Orders
ALTER TABLE public.orders 
  ADD COLUMN IF NOT EXISTS payment_method TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.orders 
  ADD CONSTRAINT orders_status_check 
  CHECK (status IN ('pending', 'paid', 'failed', 'refunded'));

-- Создать функцию для автообновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггеры для автообновления
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

### Row Level Security (RLS)

```sql
-- Включить RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users: пользователи могут читать и обновлять свои данные
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Bookings: пользователи видят свои бронирования
CREATE POLICY "Users can view own bookings" ON bookings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create bookings" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bookings" ON bookings
  FOR UPDATE USING (auth.uid() = user_id);

-- Администраторы видят всё
CREATE POLICY "Admins can view all data" ON bookings
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND isadmin = true)
  );
```

---

## 🔧 Конфигурация Supabase

1. Создайте проект на [supabase.com](https://supabase.com)
2. Обновите константы в `lib/core/constants/app_constants.dart`:
   - `supabaseUrl`
   - `supabaseAnonKey`

## 👨‍💻 Разработка

### Добавление новой фичи

1. Создайте папку в `lib/features/имя_фичи/`
2. Создайте подпапки: `domain/`, `data/`, `presentation/`
3. Добавьте маршруты в `lib/core/router/app_router.dart`

### UI компоненты

Переиспользуемые компоненты находятся в `lib/shared/widgets/`:
- `AppButton` - Кастомная кнопка
- `AppLogo` - Логотип приложения

## 📄 Лицензия

Частный проект

---

**Версия**: 1.0.0  
**Последнее обновление**: 2026-01-27
