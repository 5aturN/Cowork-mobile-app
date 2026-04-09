# DEVELOPER_HANDOVER.md - Техническая документация

## 1. О проекте (Project Overview)

**Secretaire** — это iOS/Android приложение для бронирования кабинетов, созданное для психологов.
Приложение позволяет просматривать доступность кабинетов, формировать корзину слотов и оплачивать их (бронировать).

### Ключевые особенности
*   **Слоты фиксированы**: Кабинеты сдаются по фиксированным временным интервалам (9:00, 10:30, 12:00...), а не произвольно.
*   **Facade Auth**: Авторизация по номеру телефона реализована через подмену на email/password (подробности ниже).
*   **Оплата**: На данный момент заглушка. Требуется интеграция T-Bank.

### Технический стек
*   **Framework**: Flutter 3.2+
*   **Backend**: Supabase (PostgreSQL, Realtime, Auth, Storage).
*   **State Management**: Riverpod v2.5+ (Code Generation).
*   **Navigation**: GoRouter.
*   **Maps/Utils**: Freezed, JsonSerializable, Intl.

---

## 2. Архитектура (Architecture Deep Dive)

Проект следует принципам **Feature-First Architecture** и **Riverpod Repository Pattern**.

### Поток данных (Data Flow)
`UI (Widget)` -> `Controller/Provider` -> `Repository` -> `Data Source (Supabase SDK)` -> `Database`

1.  **Presentation Layer**: Виджеты используют `ref.watch(provider)`, чтобы получить состояние.
    *   Пример: `CartPage` слушает `cartProvider` для отображения списка.
2.  **Providers**: Управляют состоянием и бизнес-логикой UI.
    *   Пример: `cartNotifier` имеет методы `addItem`, `removeItem`, которые меняют локальный список.
3.  **Domain Layer**: Содержит модели (`Booking`, `Room`) и интерфейсы репозиториев.
4.  **Data Layer**: Реализация репозиториев (`BookingRepositoryImpl`). Здесь происходит маппинг данных из JSON Supabase в Dart-объекты.

### Важные паттерны
*   **Global Cart Observer**: В `main.dart` приложение обернуто в `GlobalCartObserver`. Этот виджет следит за корзиной и **в реальном времени** проверяет доступность слотов в Supabase, чтобы предупредить пользователя, если кто-то другой занял слот, пока тот лежит в корзине.
*   **Realtime Updates**: Списки бронирований и чаты обновляются через Supabase Stream (`.stream()`), что обеспечивает мгновенную синхронизацию.

---

## 3. Подробное описание логики (Feature Logic Flows)

### 🔐 3.1. Авторизация (Auth Flow)
Файлы: `lib/features/auth/data/repositories/auth_repository_impl.dart`

В приложении нет классического SMS-подтверждения в коде репозитория (возможно, отключено или упрощено для MVP). Реализован механизм **"Facade Auth"**:
1.  Пользователь вводит телефон: `+7 999 123 45 67`.
2.  Приложение очищает номер: `79991234567`.
3.  Генерируется фейковый email: `79991234567@example.com`.
4.  Используется захардкоженный пароль: `dev-password-123!`.
5.  Попытка входа (`signInWithPassword`). Если ошибка "User not found" -> автоматическая регистрация (`signUp`).

> **Важно**: Это временное решение для разработки. В продакшене необходимо включить Supabase Phone Auth.

### 📅 3.2. Бронирование и Слоты (Booking Flow)
Файлы: `lib/features/booking/data/repositories/room_repository_impl.dart`

Логика слотов необычна — она **захардкожена** на клиенте:
1.  В `RoomRepositoryImpl` есть массив `definedSlots` (`['09:00', '10:30', ...]`).
2.  При запросе комнат репозиторий:
    *   Скачивает список комнат.
    *   Скачивает *все* бронирования на выбранную дату.
    *   В цикле сопоставляет `bookings.slot_id` (индекс) с `definedSlots`.
    *   Если совпадение найдено -> слот помечается как `occupied`.
3.  **Result**: UI получает объект `Room` уже с массивом занятых слотов.

### 💰 3.3. Кошелек и Баланс (Wallet Flow)
Файлы: `lib/features/wallet/`

*   **Баланс**: Хранится в поле `users.balance`.
*   **Транзакции**: Записываются в таблицу `transactions`.
*   **Обновление**: В коде Dart (`WalletRepository`) нет явного обновления `users.balance`. Скорее всего, это делает **Postgres Trigger** в базе данных при вставке в таблицу `transactions`.

---

## 4. База Данных (Database Schema Logic)

Основные связи таблиц:

*   **users**:
    *   `id` (PK, link to auth.users)
    *   `balance` (numeric)
*   **rooms**:
    *   `id` (PK)
    *   `available_slots` (JSON) - *фактически не используется для логики занятости, используется hardcode.*
*   **bookings**:
    *   `id` (PK)
    *   `user_id` (FK -> users.id)
    *   `room_id` (FK -> rooms.id)
    *   `slot_id` (int) - Ключевое поле! Номер слота (1, 2, 3...) соответствующий времени.
    *   `date` (date)
    *   `status` ('pending', 'confirmed', 'cancelled')
*   **transactions**:
    *   `user_id` (FK)
    *   `amount` (может быть отрицательным для списаний)
    *   `metadata` (JSON с деталями бронирования)

---

## 5. ⚠️ КРИТИЧЕСКИЕ ЗАДАЧИ (Critical Integration Tasks)

### 🔴 Задача №1: Платежная система (T-Bank)
**Статус**: Отсутствует (Mock).
**Где делать**: `lib/features/cart/presentation/pages/cart_page.dart` -> метод `_processPayment`.

**Алгоритм реализации:**
1.  В методе `_processPayment` сейчас происходит прямой вызов `_proceedWithPayment(user)`, который сразу создает бронь.
2.  **Нужно изменить:**
    *   Перед `_proceedWithPayment`: Сформировать заказ.
    *   Вызвать API T-Bank (через SDK или HTTP REST) для инициализации платежа (Init).
    *   Открыть Webview или SdkUI для оплаты.
    *   Ждать колбэк (Webhook) или поллить статус.
    *   **Только при успехе** вызывать `createBooking` и `createTransaction`.

### 🔴 Задача №2: Перенос API ключей
Ключи Supabase лежат в открытом виде в `lib/core/constants/app_constants.dart`.
Это уязвимость. Необходимо вынести их в `.env` и использовать пакет `flutter_dotenv`.

---

## 6. Установка и Запуск

1.  **Требования**: Flutter 3.2.0+, Dart 3.0+.
2.  **Зависимости**:
    ```bash
    flutter pub get
    ```
3.  **Кодогенерация** (запускать после любых правок в моделях):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
4.  **Запуск**:
    ```bash
    flutter run
    ```
    *backend поднимать не нужно, используется облачный Supabase.*

---

**Контакты**:
Если возникнут вопросы по бизнес-логике, обращайтесь к предыдущему разработчику или менеджеру проекта.
По техническим вопросам — код является "source of truth".
