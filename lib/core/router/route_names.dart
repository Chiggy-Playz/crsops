/// Central registry of every named route in the app. Both `GoRoute(name: ...)`
/// definitions and every navigation call site (`context.pushNamed(...)`)
/// reference these constants instead of raw path strings — a typo becomes a
/// compile error (undefined identifier), not a silent runtime navigation
/// failure with no route found.
class RouteNames {
  const RouteNames._();

  static const loading = 'loading';
  static const signIn = 'signIn';
  static const unauthorized = 'unauthorized';

  static const employees = 'employees';
  static const employeeNew = 'employeeNew';
  static const employeeDetail = 'employeeDetail';
  static const eventTypes = 'eventTypes';

  static const calendar = 'calendar';
  static const attendanceDay = 'attendanceDay';
  static const reports = 'reports';
  static const shiftDefaults = 'shiftDefaults';
  static const statusTypes = 'statusTypes';

  static const settings = 'settings';
  static const allowList = 'allowList';
  static const roles = 'roles';
  static const moduleAccess = 'moduleAccess';
}
