/// Utility untuk konversi tanggal Hijriah
class HijriDateUtils {
  /// Konversi tanggal Masehi ke Hijriah
  static Map<String, dynamic> toHijri(DateTime gregorian) {
    // Algoritma konversi sederhana
    int jd = _gregorianToJulian(gregorian.year, gregorian.month, gregorian.day);
    return _julianToHijri(jd);
  }

  static int _gregorianToJulian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    int a = (year / 100).floor();
    int b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;
  }

  static Map<String, dynamic> _julianToHijri(int jd) {
    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j =
        ((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor() +
        (l / 5670).floor() * ((43 * l) / 15238).floor();
    l =
        l -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    int month = ((24 * l) / 709).floor();
    int day = l - ((709 * month) / 24).floor();
    int year = 30 * n + j - 30;

    return {
      'year': year,
      'month': month,
      'day': day,
      'monthName': _getHijriMonthName(month),
    };
  }

  static String _getHijriMonthName(int month) {
    const months = [
      'Muharram',
      'Safar',
      'Rabiul Awal',
      'Rabiul Akhir',
      'Jumadil Awal',
      'Jumadil Akhir',
      'Rajab',
      'Syaban',
      'Ramadhan',
      'Syawal',
      'Dzulqaidah',
      'Dzulhijjah',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  /// Format tanggal Hijriah
  static String formatHijri(DateTime gregorian) {
    final hijri = toHijri(gregorian);
    return '${hijri['day']} ${hijri['monthName']} ${hijri['year']} H';
  }
}
