# Performance & Stability Audit

## High Priority (Critical)

### 1. Missing Error Handling in Repositories
**Files:**
- `lib/features/booking/data/repositories/booking_repository_impl.dart`
- `lib/features/wallet/data/repositories/wallet_repository_impl.dart`

**Issue:**
Network operations (Supabase calls) are performed without `try-catch` blocks.
- `createBooking`
- `getOccupiedSlotIds`
- `createTransaction`

**Fix:**
Wrap all asynchronous network calls in `try-catch` blocks. Throw custom exceptions or return `Result` types to ensure the UI can handle failures gracefully instead of crashing.

### 2. Excessive Data Streaming (Bandwidth & Performance)
**File:**
- `lib/features/booking/data/repositories/room_repository_impl.dart`

**Issue:**
The `getRooms` stream listens to the entire `bookings` table:
```dart
_supabase.from('bookings').stream(primaryKey: ['id'])
```
This downloads *every* booking record to the client, even those for other dates or rooms, before filtering them in Dart memory (`relevantBookings`). This will cause massive bandwidth usage and main-thread blocking as the database grows.

**Fix:**
Apply filters directly to the stream query if supported (e.g., `.eq('date', ...)`), or switch to a `select()` based approach with manual refresh if complex streaming filters are unavailable. At minimum, filter by `date` at the query level.

---

## Medium Priority (Memory & Logic)

### 3. Memory Leak in Dialog
**File:**
- `lib/features/sessions/presentation/pages/sessions_page.dart`

**Issue:**
Inside `_addNoteDialog`, a `TextEditingController` is instantiated but never disposed.
```dart
final controller = TextEditingController(text: session.notes ?? '');
```

**Fix:**
Refactor the dialog into a separate `StatefulWidget` or use a wrapper that ensures `controller.dispose()` is called when the dialog closes.

### 4. Mock Data Usage in Production Code
**File:**
- `lib/features/sessions/presentation/pages/sessions_page.dart`

**Issue:**
The page uses `SessionRecord.getMockSessions()` to populate the list, bypassing the real database.

**Fix:**
Connect the page to a `SessionRepository` (or `BookingRepository`) to fetch real data for the current user. Remove the mock data generator.

---

## Low Priority (Optimizations)

### 5. Repeated Regex Compilation
**File:**
- `lib/core/utils/string_utils.dart`

**Issue:**
`cleanPhoneNumber` creates a new `RegExp(r'\D')` on every call. This function is often used in tight loops or validators.

**Fix:**
Declare the RegExp as a `static final` constant:
```dart
static final _nonDigitRegex = RegExp(r'\D');
```

### 6. Uncached Images
**File:**
- `lib/features/auth/presentation/pages/auth_page.dart`

**Issue:**
Uses `Image.network` directly in the build method. This may cause image flickering and unnecessary network requests on rebuilds.

**Fix:**
Replace with `CachedNetworkImage` (package is already installed).
