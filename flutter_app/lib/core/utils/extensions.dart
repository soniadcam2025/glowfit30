import 'package:flutter/material.dart';

// ============================================
// String Extensions
// ============================================
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  /// Check if string is email
  bool get isEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is URL
  bool get isUrl {
    try {
      Uri.parse(this);
      return startsWith('http://') || startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  /// Check if string contains only digits
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Check if string is empty or whitespace
  bool get isEmptyOrWhitespace => trim().isEmpty;

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Truncate string with ellipsis
  String truncate(int length, {String ellipsis = '...'}) {
    if (this.length <= length) return this;
    return '${substring(0, length)}$ellipsis';
  }

  /// Convert to title case
  String get toTitleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}

// ============================================
// BuildContext Extensions
// ============================================
extension BuildContextExtensions on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get device padding
  EdgeInsets get devicePadding => MediaQuery.of(this).padding;

  /// Get device viewInsets (for keyboard)
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Check if device is landscape
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;

  /// Check if device is portrait
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;

  /// Check if device is mobile (max 600 width)
  bool get isMobile => screenWidth <= 600;

  /// Check if device is tablet (600-900 width)
  bool get isTablet => screenWidth > 600 && screenWidth <= 900;

  /// Check if device is desktop (>900 width)
  bool get isDesktop => screenWidth > 900;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Check if dark mode is enabled
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Show snackbar
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message);
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message);
  }

  /// Pop current route
  void pop<T>([T? result]) => Navigator.pop(this, result);

  /// Pop until
  void popUntil(String routeName) => Navigator.popUntil(this, ModalRoute.withName(routeName));
}

// ============================================
// DateTime Extensions
// ============================================
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Format date as "MMM dd, yyyy"
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} ${day.toString().padLeft(2, '0')}, $year';
  }

  /// Format time as "HH:mm"
  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Format date and time
  String get formattedDateTime => '$formattedDate $formattedTime';

  /// Get time difference in readable format
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }
}

// ============================================
// List Extensions
// ============================================
extension ListExtensions<T> on List<T> {
  /// Check if list is empty
  bool get isEmpty_ => isEmpty;

  /// Check if list is not empty
  bool get isNotEmpty_ => isNotEmpty;

  /// Get first or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Add if condition is true
  void addIfTrue(bool condition, T element) {
    if (condition) add(element);
  }

  /// Add all if condition is true
  void addAllIfTrue(bool condition, Iterable<T> elements) {
    if (condition) addAll(elements);
  }
}

// ============================================
// Duration Extensions
// ============================================
extension DurationExtensions on Duration {
  /// Format duration as "MM:SS"
  String get formatted {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format duration as "HH:MM:SS"
  String get formattedWithHours {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

// ============================================
// Int Extensions
// ============================================
extension IntExtensions on int {
  /// Convert to duration
  Duration get milliseconds => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
  Duration get days => Duration(days: this);

  /// Format number with separators
  String get formatted => toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match m) => ',',
  );
}

// ============================================
// Double Extensions
// ============================================
extension DoubleExtensions on double {
  /// Round to N decimal places
  double roundToN(int n) => (this * (10 * n)).round() / (10 * n);

  /// Format to percentage string
  String toPercentage({int decimals = 0}) {
    return '${(this * 100).roundToN(decimals)}%';
  }
}
