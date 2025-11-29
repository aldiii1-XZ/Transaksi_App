enum UserRole { owner, admin, user }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return "Owner";
      case UserRole.admin:
        return "Admin";
      case UserRole.user:
        return "User";
    }
  }
}

UserRole userRoleFromString(String? raw) {
  switch (raw?.toLowerCase()) {
    case "owner":
      return UserRole.owner;
    case "admin":
      return UserRole.admin;
    default:
      return UserRole.user;
  }
}
