/// Модель записи сессии
class SessionRecord {
  final String id;
  final String roomName;
  final DateTime dateTime;
  final int duration;
  final String? notes;
  final int price;

  const SessionRecord({
    required this.id,
    required this.roomName,
    required this.dateTime,
    required this.duration,
    this.notes,
    required this.price,
  });

  String get formattedDate {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String get formattedTime {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final endTime = dateTime.add(Duration(hours: duration));
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute - $endHour:$endMinute';
  }

  // Mock данные
  static List<SessionRecord> getMockSessions() {
    final now = DateTime.now();

    return [
      SessionRecord(
        id: '1',
        roomName: 'Кабинет №3 - Уют',
        dateTime: now.subtract(const Duration(days: 2, hours: -14)),
        duration: 1,
        price: 500,
        notes: 'Клиент работал над проблемами тревожности. Хороший прогресс.',
      ),
      SessionRecord(
        id: '2',
        roomName: 'Кабинет №5 - Тишина',
        dateTime: now.subtract(const Duration(days: 5, hours: -10)),
        duration: 2,
        price: 1200,
        notes:
            'Групповая сессия прошла отлично. Активное участие всех членов группы.',
      ),
      SessionRecord(
        id: '3',
        roomName: 'Кабинет №3 - Уют',
        dateTime: now.subtract(const Duration(days: 9, hours: -16)),
        duration: 1,
        price: 500,
      ),
      SessionRecord(
        id: '4',
        roomName: 'Кабинет №7 - Группа',
        dateTime: now.subtract(const Duration(days: 14, hours: -10)),
        duration: 2,
        price: 1600,
        notes: 'Терапевтическая сессия. Обсудили новые стратегии совладания.',
      ),
      SessionRecord(
        id: '5',
        roomName: 'Кабинет №5 - Тишина',
        dateTime: now.subtract(const Duration(days: 21, hours: -14)),
        duration: 1,
        price: 600,
        notes: 'Первичная консультация. Установлен контакт с клиентом.',
      ),
      SessionRecord(
        id: '6',
        roomName: 'Кабинет №3 - Уют',
        dateTime: now.subtract(const Duration(days: 28, hours: -15)),
        duration: 1,
        price: 500,
      ),
      SessionRecord(
        id: '7',
        roomName: 'Кабинет №7 - Группа',
        dateTime: now.subtract(const Duration(days: 35, hours: -11)),
        duration: 2,
        price: 1600,
        notes:
            'Работа с семейными отношениями. Прорыв в понимании паттернов поведения.',
      ),
    ];
  }
}
