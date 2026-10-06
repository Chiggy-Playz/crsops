import 'core/clients/clients_section.dart';
import 'core/employees/employees_section.dart';
import 'core/sections/app_section.dart';
import 'core/settings/settings_section.dart';
import 'modules/attendance/attendance_section.dart';
import 'modules/challans/challans_section.dart';

/// The composition root's section list, in nav order — the one place that
/// knows every section. Adding a module (challan, asset) means one line here.
final allSections = <AppSection>[
  attendanceSection,
  challansSection,
  clientsSection,
  employeesSection,
  settingsSection,
];
