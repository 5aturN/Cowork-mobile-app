/// Строковые ресурсы приложения (русский язык)
class AppStrings {
  // Welcome Screen
  static const String welcomeTitle = 'Пространство для профессионалов';
  static const String welcomeSubtitle = 
      'Арендуйте уютные кабинеты для консультаций в один клик. '
      'Тишина, комфорт и конфиденциальность для вас и ваших клиентов.';
  static const String welcomeButtonText = 'Начать';
  static const String welcomeLoginText = 'Уже есть аккаунт? ';
  static const String welcomeLoginButton = 'Войти';
  
  // Auth Screen
  static const String loginTitle = 'Вход';
  static const String registerTitle = 'Регистрация';
  static const String email = 'Email';
  static const String password = 'Пароль';
  static const String confirmPassword = 'Подтвердите пароль';
  static const String forgotPassword = 'Забыли пароль?';
  static const String loginButton = 'Войти';
  static const String registerButton = 'Зарегистрироваться';
  static const String noAccount = 'Нет аккаунта? ';
  static const String haveAccount = 'Уже есть аккаунт? ';
  static const String signUp = 'Зарегистрироваться';
  static const String signIn = 'Войти';
  
  // Booking Screen
  static const String bookingTitle = 'Бронирование';
  static const String greeting = 'Добрый день';
  static const String selectDate = 'Выберите дату';
  static const String selectTime = 'Выберите время';
  static const String availableRooms = 'Доступные кабинеты';
  static const String availableTime = 'Доступное время';
  static const String bookButton = 'Забронировать';
  static const String price = 'Цена';
  static const String perHour = 'в час';
  static const String available = 'Доступно';
  static const String occupied = 'Занято';
  static const String squareMeters = 'м²';
  
  // Filters
  static const String all = 'Все';
  static const String withWindow = 'С окном';
  static const String forGroups = 'Для групп';
  static const String withCouch = 'Кушетка';
  static const String softLight = 'Мягкий свет';
  
  // My Bookings Screen
  static const String myBookings = 'Мои бронирования';
  static const String upcoming = 'Предстоящие';
  static const String past = 'Прошедшие';
  static const String noBookings = 'У вас пока нет бронирований';
  static const String cancelBooking = 'Отменить';
  
  // Session Records Screen
  static const String sessionRecords = 'Записи сессий';
  static const String noRecords = 'Записей пока нет';
  
  // Profile Screen
  static const String profile = 'Профиль';
  static const String editProfile = 'Редактировать профиль';
  static const String settings = 'Настройки';
  static const String logout = 'Выйти';
  static const String name = 'Имя';
  static const String phone = 'Телефон';
  static const String saveChanges = 'Сохранить изменения';
  
  // Navigation
  static const String navBooking = 'Бронь';
  static const String navSessions = 'Сессии';
  static const String navProfile = 'Профиль';
  
  // Common
  static const String cancel = 'Отмена';
  static const String confirm = 'Подтвердить';
  static const String save = 'Сохранить';
  static const String delete = 'Удалить';
  static const String edit = 'Редактировать';
  static const String close = 'Закрыть';
  static const String error = 'Ошибка';
  static const String success = 'Успешно';
  static const String loading = 'Загрузка...';
  
  // Error Messages
  static const String errorGeneric = 'Произошла ошибка. Попробуйте еще раз.';
  static const String errorNetwork = 'Проверьте подключение к интернету';
  static const String errorAuth = 'Ошибка авторизации';
  static const String errorInvalidEmail = 'Неверный формат email';
  static const String errorPasswordMismatch = 'Пароли не совпадают';
  static const String errorPasswordTooShort = 'Пароль должен содержать минимум 6 символов';
  static const String errorFieldRequired = 'Это поле обязательно';
}
