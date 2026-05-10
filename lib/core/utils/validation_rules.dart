class ValidationRules {
  /// Regular expression for a valid email address.
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  /// Regular expression for Bangladeshi phone numbers.
  /// Matches formats like: 01712345678, +8801712345678, 8801712345678
  static final RegExp _phoneRegex = RegExp(r'^(?:\+88|88)?(01[3-9]\d{8})$');

  /// Regular expression for University ID constraint (e.g. 54/21).
  static final RegExp _universityIdRegex = RegExp(r'^\d+/\d+$');

  /// Regular expression for Class Roll format (e.g. CSE-10 or 10).
  static final RegExp _classRollRegex = RegExp(r'^[a-zA-Z0-9\-]+$');

  /// Regular expression for Academic Session format (e.g. 2020-2021).
  static final RegExp _sessionRegex = RegExp(r'^\d{4}-\d{4}$');

  /// Regular expression for DU Registration number format (typically 10 digits).
  static final RegExp _duRegRegex = RegExp(r'^\d{6,12}$');

  /// Regular expression for URL verification (e.g. apply links, github urls).
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );

  /// Validates a required text field.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password constraints (Min 6 chars, alphanumeric).
  static String? validatePassword(String? value, {bool isSignup = true}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (isSignup) {
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
      if (!RegExp(r'[a-zA-Z]').hasMatch(value) || !RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password must contain both letters and numbers';
      }
    }
    return null;
  }

  /// Validates phone number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phone = value.trim();
    if (!_phoneRegex.hasMatch(phone)) {
      return 'Enter a valid 11-digit Bangladeshi phone number';
    }
    return null;
  }

  /// Validates University/Student ID.
  static String? validateUniversityId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'University ID is required';
    }
    final id = value.trim();
    if (!_universityIdRegex.hasMatch(id)) {
      return 'Enter valid ID format (e.g., 54/21)';
    }
    return null;
  }

  /// Validates Class Roll format.
  static String? validateClassRoll(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Class Roll is required';
    }
    final roll = value.trim();
    if (!_classRollRegex.hasMatch(roll)) {
      return 'Enter valid Class Roll (e.g., CSE-10 or 10)';
    }
    return null;
  }

  /// Validates DU Registration format.
  static String? validateDuReg(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'DU Registration number is required';
    }
    final duReg = value.trim();
    if (!_duRegRegex.hasMatch(duReg)) {
      return 'Enter valid DU Registration (6-12 digits)';
    }
    return null;
  }

  /// Validates Academic Session format.
  static String? validateSession(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Session is required';
    }
    final session = value.trim();
    if (!_sessionRegex.hasMatch(session)) {
      return 'Enter valid session format (e.g., 2020-2021)';
    }
    return null;
  }

  /// Validates general URL format.
  static String? validateUrl(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName URL is required';
    }
    final url = value.trim();
    if (!_urlRegex.hasMatch(url)) {
      return 'Enter a valid URL (starting with http:// or https://)';
    }
    return null;
  }

  /// Validates optional URL format (passes if empty).
  static String? validateOptionalUrl(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validateUrl(value, fieldName);
  }
}
