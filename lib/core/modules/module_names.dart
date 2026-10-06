/// Registry of module ids exactly as seeded in `core.modules` (and granted
/// via `core.module_access`). Add future modules (challan, asset) here as
/// one line each — call sites reference `ModuleNames.x`, never raw strings,
/// so a rename or typo fails at compile time, not in production.
/// This is the *module registry* id, not the Postgres schema name.
abstract final class ModuleNames {
  static const attendance = 'attendance';
  static const challans = 'challans';
}
