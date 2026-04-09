extension SupabaseDate on DateTime {
  /// Returns the date formatted as YYYY-MM-DD, strict for Supabase Date columns.
  String toSupabaseDate() {
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }
}
