class StringUtils {
  static final _nonDigitRegex = RegExp(r'\D');

  /// Removes all non-numeric characters from the string.
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(_nonDigitRegex, '');
  }

  /// Formats a cleaned phone number (digits only) to +7 (xxx) xxx-xx-xx format.
  /// Handles input starting with 7, 8, or no country code.
  static String formatPhoneNumber(String phone) {
    String rawPhone = cleanPhoneNumber(phone);

    if (rawPhone.startsWith('8')) {
      rawPhone = '7${rawPhone.substring(1)}';
    }

    if (rawPhone.isNotEmpty && !rawPhone.startsWith('7')) {
      rawPhone = '7$rawPhone';
    }

    if (rawPhone.length == 11) {
      return '+${rawPhone[0]} (${rawPhone.substring(1, 4)}) ${rawPhone.substring(4, 7)}-${rawPhone.substring(7, 9)}-${rawPhone.substring(9)}';
    } else {
      return '+$rawPhone';
    }
  }
}
