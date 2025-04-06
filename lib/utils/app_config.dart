/// Configuration constants for the application
class AppConfig {
  // App version information
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Feature flags
  static const bool enableProviderSignup = false;
  static const bool enableAppleSignIn = false;
}

/// User role definitions
class RoleTypes {
  static const String patient = 'patient';
  static const String provider = 'provider';

  // Future role types can be added here
  // static const String admin = 'admin';
  // static const String staff = 'staff';

  // Helper method to check if a role is valid
  static bool isValidRole(String role) {
    return role == patient || role == provider;
  }

  // Helper to get display name for a role
  static String getDisplayName(String role) {
    switch (role) {
      case patient:
        return 'Patient';
      case provider:
        return 'Healthcare Provider';
      default:
        return 'Unknown Role';
    }
  }
}
