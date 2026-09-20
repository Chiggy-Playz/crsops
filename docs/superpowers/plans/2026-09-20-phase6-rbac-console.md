# CRS Ops — Phase 6: RBAC Console Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In-app screens for the three admin-console actions plan.md calls for (signup allow-list, roles, module access) plus a `SettingsPage` entry point linking to these and the existing Phase 2/3 admin screens — closing out req. 7's "no SQL for routine config" goal.

**Architecture:** No new Postgres — `core.allowed_signup_emails`/`core.user_roles`/`core.roles`/`core.module_access`/`core.modules`/`core.profiles` all exist from Phase 1 with sufficient RLS already. This phase is Flutter-only: one `Profile` model, one cohesive `AdminRepository` (these three concerns are tightly coupled "who can do what" actions, unlike the one-repo-per-table pattern used where each table had independent behavior), three admin pages, and a `SettingsPage`.

**Tech Stack:** Same as Phases 1–5 — Flutter (Riverpod + `riverpod_generator`, `dart_mappable`), Supabase (`core` schema, unchanged this phase).

**Spec:** `/home/chiggy/Projects/crs_ops/plan.md` (Screens → Settings/admin console; RLS pattern / Bootstrap section). Depends on Phase 1 (`core` schema + `AppSession`/`sessionProvider`), Phase 2 (route-redirect pattern precedent).

**Scope note, per explicit instruction:** this plan skips test-writing entirely (no test files, no TDD steps) — every task still specifies complete, real implementation code and a `dart analyze` compile-check, just no test ceremony. Tests are being deprioritized for time; add them in a later pass.

## Global Constraints

- **No new migration.** Confirmed by reading `supabase/migrations/20260919223302_core_schema.sql` directly: `allowed_signup_emails_write`/`user_roles_write` policies are superadmin-only `for all` (covers insert/delete); `module_access_write` is admin-or-above `for all`; `profiles_select_own_or_admin` lets admin-or-above read every profile; `modules_select_authenticated` lets any signed-in user read the module list. Every method this plan needs is already permitted.
- **Scope matches plan.md's exact verbs, not more**: allow-list is "add/remove" (delete included), roles is "grant/revoke" (delete included), module access is "grant" only (no revoke button this phase — not asked for, not added speculatively).
- Every `.from('<table>')` call must be `.schema('core')`-qualified, written adjacent on the same line as `.from(` every time (the exact bug that recurred twice before this became a from-the-start habit in Phases 3–5).
- Riverpod resolved to **3.x**: `AsyncValue.value` (nullable), not `.valueOrNull`.
- **Every button whose action requires N conditions checks all N in its enabled-state** — the Phase 4 lesson (a Save button enabled on one condition while the save logic silently required a second, unmet one). Checked explicitly per dialog below.
- **The nav-shell gap, decided explicitly**: no screen anywhere currently uses `AdaptiveNavScaffold` for real persistent cross-module navigation (Phase 1's placeholder that did was deleted when Phase 3 made Calendar the real home route). Building that out for real means restructuring the router around a `StatefulShellRoute`/shell-aware navigation model — a cross-cutting change to the whole route tree, not a Settings-specific concern, and genuinely risky to do correctly under time pressure in the same phase as three new data-writing admin screens. **Decision: defer the full nav shell to a later polish pass; make Settings reachable now the exact same way Phase 5 made Reports reachable** — an `AppBar` icon on `CalendarPage`. This keeps today's change low-risk and consistent with an already-established pattern, at the cost of Settings not yet being a persistent nav destination the way plan.md's long-term design calls for.
- English only, Material 3 widgets throughout.

---

## File Structure

**New — `lib/core/auth/` (RBAC console data belongs with the auth/session domain that already owns `core`'s auth-adjacent tables, even though its pages live in the settings module):**
- `models/profile.dart` — `Profile` (`dart_mappable`).
- `repositories/admin_repository.dart` — `abstract class AdminRepository` + `SupabaseAdminRepository`.
- `providers/admin_providers.dart` — all `@riverpod` providers for this phase.

**New — `lib/modules/settings/` (per plan.md's own file tree, Settings is a module):**
- `pages/settings_page.dart`
- `pages/allow_list_manager_page.dart`
- `pages/roles_manager_page.dart`
- `pages/module_access_manager_page.dart`
- `routes.dart`

**Modify:**
- `lib/core/router/app_router.dart` — splice in `settingsRoutes(ref)`.
- `lib/modules/attendance/pages/calendar_page.dart` — add a Settings `AppBar` action.

---

### Task 1: Confirm no new schema/migration is needed

**Files:** none — verification only.

- [ ] **Step 1: Re-confirm the RLS policies this plan relies on**

```bash
grep -n -A3 "allowed_signup_emails_write\|user_roles_write\|module_access_write\|profiles_select_own_or_admin\|modules_select_authenticated" supabase/migrations/20260919223302_core_schema.sql
```

Expected: `allowed_signup_emails_write`/`user_roles_write` are superadmin-only `for all`; `module_access_write` is admin-or-above `for all`; `profiles_select_own_or_admin` allows admin-or-above to read every row; `modules_select_authenticated` allows any authenticated read. If any of these differ from this description, **stop and report it** before proceeding — this plan's RLS-dependent UI assumes exactly this shape.

- [ ] **Step 2: No commit** — verification only.

---

### Task 2: `Profile` model

**Files:**
- Create: `lib/core/auth/models/profile.dart`

**Interfaces:**
- Produces: `class Profile` (`dart_mappable`) — `String id`, `String email`, `DateTime createdAt`.

- [ ] **Step 1: Write the model**

```dart
// lib/core/auth/models/profile.dart
import 'package:dart_mappable/dart_mappable.dart';

part 'profile.mapper.dart';

@MappableClass()
class Profile with ProfileMappable {
  const Profile({required this.id, required this.email, required this.createdAt});

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'email')
  final String email;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
}
```

- [ ] **Step 2: Generate mapper code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/auth/models/profile.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/auth/models/profile.dart lib/core/auth/models/profile.mapper.dart
git commit -m "feat: Profile model"
```

---

### Task 3: `AdminRepository`

**Files:**
- Create: `lib/core/auth/repositories/admin_repository.dart`

**Interfaces:**
- Consumes: `Profile` (Task 2), `translateException` (Phase 1).
- Produces: `abstract class AdminRepository` (`fetchAllowedEmails`, `addAllowedEmail`, `removeAllowedEmail`, `fetchProfiles`, `fetchUserRoles`, `grantRole`, `revokeRole`, `fetchModules`, `fetchModuleAccess`, `grantModuleAccess`) + `SupabaseAdminRepository`. **Every one of the 10 `.from()` call sites below is `.schema('core')`-qualified on the same line.**

- [ ] **Step 1: Write the repository**

```dart
// lib/core/auth/repositories/admin_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/profile.dart';

abstract class AdminRepository {
  Future<List<({String email, String? note, DateTime addedAt})>> fetchAllowedEmails();
  Future<void> addAllowedEmail({required String email, String? note});
  Future<void> removeAllowedEmail(String email);

  Future<List<Profile>> fetchProfiles();

  /// One role per user, using the same superadmin > admin > employee
  /// precedence as Phase 1's RolesRepository.fetchRole, in case more than
  /// one row somehow exists for a user.
  Future<Map<String, String>> fetchUserRoles();
  Future<void> grantRole({required String userId, required String roleId});
  Future<void> revokeRole({required String userId, required String roleId});

  Future<List<({String id, String name})>> fetchModules();
  Future<Map<String, Set<String>>> fetchModuleAccess();
  Future<void> grantModuleAccess({required String userId, required String moduleId});
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<({String email, String? note, DateTime addedAt})>> fetchAllowedEmails() async {
    try {
      final rows = await _client.schema('core').from('allowed_signup_emails').select().order('added_at', ascending: false);
      return rows
          .map((r) => (
                email: r['email'] as String,
                note: r['note'] as String?,
                addedAt: DateTime.parse(r['added_at'] as String),
              ))
          .toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> addAllowedEmail({required String email, String? note}) async {
    try {
      await _client.schema('core').from('allowed_signup_emails').insert({'email': email, 'note': note});
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> removeAllowedEmail(String email) async {
    try {
      await _client.schema('core').from('allowed_signup_emails').delete().eq('email', email);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<Profile>> fetchProfiles() async {
    try {
      final rows = await _client.schema('core').from('profiles').select().order('email');
      return rows.map(ProfileMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Map<String, String>> fetchUserRoles() async {
    try {
      final rows = await _client.schema('core').from('user_roles').select('user_id, role_id');
      final byUser = <String, Set<String>>{};
      for (final r in rows) {
        final userId = r['user_id'] as String;
        final roleId = r['role_id'] as String;
        byUser.putIfAbsent(userId, () => {}).add(roleId);
      }
      return {
        for (final entry in byUser.entries)
          entry.key: entry.value.contains('superadmin')
              ? 'superadmin'
              : entry.value.contains('admin')
                  ? 'admin'
                  : 'employee',
      };
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> grantRole({required String userId, required String roleId}) async {
    try {
      await _client.schema('core').from('user_roles').upsert(
        {'user_id': userId, 'role_id': roleId},
        onConflict: 'user_id,role_id',
      );
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> revokeRole({required String userId, required String roleId}) async {
    try {
      await _client.schema('core').from('user_roles').delete().eq('user_id', userId).eq('role_id', roleId);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<({String id, String name})>> fetchModules() async {
    try {
      final rows = await _client.schema('core').from('modules').select('id, name').order('id');
      return rows.map((r) => (id: r['id'] as String, name: r['name'] as String)).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Map<String, Set<String>>> fetchModuleAccess() async {
    try {
      final rows = await _client.schema('core').from('module_access').select('user_id, module_id');
      final byUser = <String, Set<String>>{};
      for (final r in rows) {
        final userId = r['user_id'] as String;
        final moduleId = r['module_id'] as String;
        byUser.putIfAbsent(userId, () => {}).add(moduleId);
      }
      return byUser;
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> grantModuleAccess({required String userId, required String moduleId}) async {
    try {
      await _client.schema('core').from('module_access').upsert(
        {'user_id': userId, 'module_id': moduleId},
        onConflict: 'user_id,module_id',
      );
    } catch (error) {
      throw translateException(error);
    }
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/core/auth/repositories/admin_repository.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/auth/repositories/admin_repository.dart
git commit -m "feat: AdminRepository — allow-list, roles, module access (schema-qualified)"
```

---

### Task 4: Riverpod providers

**Files:**
- Create: `lib/core/auth/providers/admin_providers.dart`

**Interfaces:**
- Consumes: `supabaseClientProvider` (Phase 1), `AdminRepository` (Task 3).
- Produces: `adminRepositoryProvider` (`keepAlive`); `allowedEmailsProvider`, `profilesProvider`, `userRolesProvider`, `modulesProvider`, `moduleAccessProvider` → their respective `AsyncValue<...>` types.

- [ ] **Step 1: Write the providers**

```dart
// lib/core/auth/providers/admin_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supabase_client_provider.dart';
import '../models/profile.dart';
import '../repositories/admin_repository.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) => SupabaseAdminRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<({String email, String? note, DateTime addedAt})>> allowedEmails(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchAllowedEmails();

@riverpod
Future<List<Profile>> profiles(Ref ref) => ref.watch(adminRepositoryProvider).fetchProfiles();

@riverpod
Future<Map<String, String>> userRoles(Ref ref) => ref.watch(adminRepositoryProvider).fetchUserRoles();

@riverpod
Future<List<({String id, String name})>> modules(Ref ref) => ref.watch(adminRepositoryProvider).fetchModules();

@riverpod
Future<Map<String, Set<String>>> moduleAccess(Ref ref) => ref.watch(adminRepositoryProvider).fetchModuleAccess();
```

- [ ] **Step 2: Generate code and verify it compiles**

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/core/auth/providers/
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/auth/providers/admin_providers.dart lib/core/auth/providers/admin_providers.g.dart
git commit -m "feat: admin console Riverpod providers"
```

---

### Task 5: `AllowListManagerPage`

**Files:**
- Create: `lib/modules/settings/pages/allow_list_manager_page.dart`

**Interfaces:**
- Consumes: `allowedEmailsProvider`, `adminRepositoryProvider` (Task 4).
- Produces: `class AllowListManagerPage extends ConsumerStatefulWidget`.

- [ ] **Step 1: Write the page**

```dart
// lib/modules/settings/pages/allow_list_manager_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/admin_providers.dart';

class AllowListManagerPage extends ConsumerStatefulWidget {
  const AllowListManagerPage({super.key});

  @override
  ConsumerState<AllowListManagerPage> createState() => _AllowListManagerPageState();
}

class _AllowListManagerPageState extends ConsumerState<AllowListManagerPage> {
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  bool get _canAdd => _emailController.text.trim().isNotEmpty;

  Future<void> _add() async {
    await ref.read(adminRepositoryProvider).addAllowedEmail(
          email: _emailController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
    _emailController.clear();
    _noteController.clear();
    ref.invalidate(allowedEmailsProvider);
    setState(() {});
  }

  Future<void> _remove(String email) async {
    await ref.read(adminRepositoryProvider).removeAllowedEmail(email);
    ref.invalidate(allowedEmailsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final emailsAsync = ref.watch(allowedEmailsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Signup allow-list')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _canAdd ? _add : null, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: emailsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (emails) {
                if (emails.isEmpty) {
                  return const Center(child: Text('No allow-listed emails yet'));
                }
                return ListView.builder(
                  itemCount: emails.length,
                  itemBuilder: (context, index) {
                    final entry = emails[index];
                    return ListTile(
                      title: Text(entry.email),
                      subtitle: entry.note == null ? null : Text(entry.note!),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(entry.email),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

*(`_canAdd` only requires a non-empty email, matching `_add()`'s actual requirement exactly — note is genuinely optional in both the check and the call.)*

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/modules/settings/pages/allow_list_manager_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/modules/settings/pages/allow_list_manager_page.dart
git commit -m "feat: signup allow-list manager page"
```

---

### Task 6: `RolesManagerPage`

**Files:**
- Create: `lib/modules/settings/pages/roles_manager_page.dart`

**Interfaces:**
- Consumes: `profilesProvider`, `userRolesProvider`, `adminRepositoryProvider` (Task 4).
- Produces: `class RolesManagerPage extends ConsumerWidget`.

- [ ] **Step 1: Write the page**

```dart
// lib/modules/settings/pages/roles_manager_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/admin_providers.dart';

class RolesManagerPage extends ConsumerWidget {
  const RolesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final rolesAsync = ref.watch(userRolesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Roles')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('No profiles yet — nobody has signed in'));
          }
          final roles = rolesAsync.value ?? const {};
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final role = roles[profile.id];
              return ListTile(
                title: Text(profile.email),
                subtitle: Text(role == null ? 'No role granted' : 'Role: $role'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => _EditRoleDialog(profileId: profile.id, currentRole: role),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EditRoleDialog extends ConsumerStatefulWidget {
  const _EditRoleDialog({required this.profileId, required this.currentRole});
  final String profileId;
  final String? currentRole;

  @override
  ConsumerState<_EditRoleDialog> createState() => _EditRoleDialogState();
}

class _EditRoleDialogState extends ConsumerState<_EditRoleDialog> {
  late String? _selectedRole = widget.currentRole;

  bool get _canSave => _selectedRole != null && _selectedRole != widget.currentRole;

  Future<void> _save() async {
    final repo = ref.read(adminRepositoryProvider);
    if (widget.currentRole != null) {
      await repo.revokeRole(userId: widget.profileId, roleId: widget.currentRole!);
    }
    await repo.grantRole(userId: widget.profileId, roleId: _selectedRole!);
    ref.invalidate(userRolesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change role'),
      content: DropdownButton<String>(
        value: _selectedRole,
        hint: const Text('Select a role'),
        items: const ['superadmin', 'admin', 'employee']
            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
            .toList(),
        onChanged: (value) => setState(() => _selectedRole = value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _canSave ? _save : null, child: const Text('Save')),
      ],
    );
  }
}
```

*(`_canSave` requires both a non-null selection AND that it actually differs from the current role — prevents both the Phase-4-style "save does nothing" case and a pointless revoke+grant of the same role. `_save()`'s revoke-then-grant sequence keeps a user from accumulating multiple `user_roles` rows, matching Phase 1's `fetchRole`/this phase's `fetchUserRoles` precedence-resolution logic staying meaningful.)*

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/modules/settings/pages/roles_manager_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/modules/settings/pages/roles_manager_page.dart
git commit -m "feat: roles manager page"
```

---

### Task 7: `ModuleAccessManagerPage`

**Files:**
- Create: `lib/modules/settings/pages/module_access_manager_page.dart`

**Interfaces:**
- Consumes: `profilesProvider`, `moduleAccessProvider`, `modulesProvider`, `adminRepositoryProvider` (Task 4).
- Produces: `class ModuleAccessManagerPage extends ConsumerWidget`.

- [ ] **Step 1: Write the page**

```dart
// lib/modules/settings/pages/module_access_manager_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/admin_providers.dart';

class ModuleAccessManagerPage extends ConsumerWidget {
  const ModuleAccessManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final accessAsync = ref.watch(moduleAccessProvider);
    final modulesAsync = ref.watch(modulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Module access')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('No profiles yet — nobody has signed in'));
          }
          final access = accessAsync.value ?? const {};
          final modules = modulesAsync.value ?? const [];
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final granted = access[profile.id] ?? const <String>{};
              return ListTile(
                title: Text(profile.email),
                subtitle: Text(granted.isEmpty ? 'No module access granted' : granted.join(', ')),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Grant module access',
                  onPressed: modules.isEmpty
                      ? null
                      : () => showDialog<void>(
                            context: context,
                            builder: (context) => _GrantModuleAccessDialog(profileId: profile.id, modules: modules),
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GrantModuleAccessDialog extends ConsumerStatefulWidget {
  const _GrantModuleAccessDialog({required this.profileId, required this.modules});
  final String profileId;
  final List<({String id, String name})> modules;

  @override
  ConsumerState<_GrantModuleAccessDialog> createState() => _GrantModuleAccessDialogState();
}

class _GrantModuleAccessDialogState extends ConsumerState<_GrantModuleAccessDialog> {
  String? _selectedModuleId;

  Future<void> _grant() async {
    await ref.read(adminRepositoryProvider).grantModuleAccess(
          userId: widget.profileId,
          moduleId: _selectedModuleId!,
        );
    ref.invalidate(moduleAccessProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grant module access'),
      content: DropdownButton<String>(
        value: _selectedModuleId,
        hint: const Text('Select a module'),
        items: widget.modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
        onChanged: (value) => setState(() => _selectedModuleId = value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _selectedModuleId != null ? _grant : null, child: const Text('Grant')),
      ],
    );
  }
}
```

*(Grant button's enabled-check (`_selectedModuleId != null`) matches `_grant()`'s only requirement — the `!` on `_selectedModuleId!` inside `_grant` is safe precisely because the button can't be pressed while it's null.)*

- [ ] **Step 2: Verify it compiles**

```bash
dart analyze lib/modules/settings/pages/module_access_manager_page.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/modules/settings/pages/module_access_manager_page.dart
git commit -m "feat: module access manager page"
```

---

### Task 8: `SettingsPage`, routes, and reachability from Calendar

**Files:**
- Create: `lib/modules/settings/pages/settings_page.dart`
- Create: `lib/modules/settings/routes.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/modules/attendance/pages/calendar_page.dart`

**Interfaces:**
- Consumes: `sessionProvider`, `authRepositoryProvider` (Phase 1); the three pages (Tasks 5–7); existing routes `/employees/event-types`, `/attendance/shift-defaults`, `/attendance/status-types` (Phases 2–3).
- Produces: `class SettingsPage extends ConsumerWidget`; `List<RouteBase> settingsRoutes(Ref ref)`.

- [ ] **Step 1: Write `SettingsPage`** — tiles gated by the exact same role check each target route already enforces via redirect

```dart
// lib/modules/settings/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final isSuperadmin = session?.isSuperadmin ?? false;
    final isAdminOrAbove = session?.isAdminOrAbove ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Signup allow-list'),
              onTap: () => Navigator.of(context).pushNamed('/settings/allow-list'),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Roles'),
              onTap: () => Navigator.of(context).pushNamed('/settings/roles'),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.apps_outlined),
              title: const Text('Module access'),
              onTap: () => Navigator.of(context).pushNamed('/settings/module-access'),
            ),
          if (isSuperadmin)
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Event types'),
              onTap: () => Navigator.of(context).pushNamed('/employees/event-types'),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Shift defaults'),
              onTap: () => Navigator.of(context).pushNamed('/attendance/shift-defaults'),
            ),
          if (isAdminOrAbove)
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Attendance status types'),
              onTap: () => Navigator.of(context).pushNamed('/attendance/status-types'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write `routes.dart`**

```dart
// lib/modules/settings/routes.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/providers/auth_providers.dart';
import 'pages/allow_list_manager_page.dart';
import 'pages/module_access_manager_page.dart';
import 'pages/roles_manager_page.dart';
import 'pages/settings_page.dart';

List<RouteBase> settingsRoutes(Ref ref) => [
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
      GoRoute(
        path: '/settings/allow-list',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isSuperadmin ? null : '/unauthorized';
        },
        builder: (context, state) => const AllowListManagerPage(),
      ),
      GoRoute(
        path: '/settings/roles',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isSuperadmin ? null : '/unauthorized';
        },
        builder: (context, state) => const RolesManagerPage(),
      ),
      GoRoute(
        path: '/settings/module-access',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isAdminOrAbove ? null : '/unauthorized';
        },
        builder: (context, state) => const ModuleAccessManagerPage(),
      ),
    ];
```

- [ ] **Step 3: Splice into `app_router.dart`** — add the import and one line in the routes list, do not remove anything existing

```dart
// lib/core/router/app_router.dart — add this import alongside the other module route imports:
import '../../modules/settings/routes.dart';
// add this to the existing routes list, alongside ...employeeRoutes(ref)/...attendanceRoutes(ref):
      ...settingsRoutes(ref),
```

- [ ] **Step 4: Add a Settings action to `CalendarPage`'s `AppBar`** — alongside the existing Reports icon from Phase 5, per this plan's stated nav-shell deferral decision

```dart
// lib/modules/attendance/pages/calendar_page.dart — AppBar becomes:
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Reports',
            onPressed: () => Navigator.of(context).pushNamed('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
```

- [ ] **Step 5: Verify it compiles**

```bash
dart analyze lib/modules/settings/ lib/core/router/ lib/modules/attendance/pages/calendar_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/modules/settings/pages/settings_page.dart lib/modules/settings/routes.dart lib/core/router/app_router.dart lib/modules/attendance/pages/calendar_page.dart
git commit -m "feat: Settings page + RBAC console routes, reachable from Calendar's app bar"
```

---

### Task 9: Full-phase compile sweep + schema-qualification audit

**Files:** none (verification only).

- [ ] **Step 1: Schema-qualification audit**

```bash
grep -n "\.from(" lib/core/auth/repositories/admin_repository.dart
```

Expected: **10 call sites**, every one immediately preceded by `.schema('core')` on the same line — `fetchAllowedEmails`/`addAllowedEmail`/`removeAllowedEmail` (3), `fetchProfiles` (1), `fetchUserRoles`/`grantRole`/`revokeRole` (3), `fetchModules` (1), `fetchModuleAccess`/`grantModuleAccess` (2). If any is missing it, fix now and re-run.

- [ ] **Step 2: Run the full analyzer**

```bash
flutter analyze
```

Expected: no errors.

- [ ] **Step 3: No commit** — verification only, unless Step 1 found and fixed something (commit that fix first).

---

## Self-Review

- **Spec coverage**: allow-list add/remove (Task 5), roles grant/revoke (Task 6), module access grant (Task 7) — matching plan.md's exact verbs per screen, no more. `SettingsPage` as the entry point for these plus the three pre-existing Phase 2/3 admin screens (Task 8), gated identically to how each target route already redirects.
- **The bootstrap exception, correctly out of scope**: plan.md is explicit the very first superadmin grant and first two allow-listed emails can never happen through this console (no superadmin logged in yet to use it) — this plan doesn't attempt to solve that, matching the spec.
- **Nav-shell gap**: explicitly decided and stated in Global Constraints, not silently skipped — Settings reached via a Calendar app-bar icon (matching Phase 5's Reports precedent) rather than a full persistent `AdaptiveNavScaffold` shell, which would be a larger, riskier, cross-cutting router change deferred to a later polish pass.
- **Placeholder scan**: no `TBD`/`TODO`/`FIXME`. No theme toggle added (plan.md mentions one for Settings, but it's cosmetic polish unrelated to RBAC — adding a non-functional toggle would violate the no-placeholders rule; a real one belongs in a polish phase).
- **Enabled-state audit (the Phase 4 bug class)**: `AllowListManagerPage`'s Add button checks exactly what `_add()` needs (non-empty email). `RolesManagerPage`'s Save button checks a role is selected AND differs from current (matching `_save()`'s revoke+grant logic, and avoiding a pointless no-op write). `ModuleAccessManagerPage`'s Grant button checks a module is selected, matching `_grant()`'s only requirement.
- **Schema-qualification**: 10 call sites in `AdminRepository`, every one written `.schema('core').from(...)` adjacent on the same line — verified by `grep` while writing this plan, re-verified as Task 9's explicit checkpoint.
- **Import-path check**: pages in `lib/modules/settings/pages/` importing `lib/core/auth/...` use `../../../core/...` (3 levels up to `lib/`) — verified against Phase 3's identical-depth precedent (`lib/modules/attendance/pages/attendance_day_page.dart` importing `../../../core/employees/...`). `routes.dart` at `lib/modules/settings/` importing `lib/core/auth/...` uses `../../core/...` (2 levels), matching `lib/modules/attendance/routes.dart`'s identical import exactly. `app_router.dart`'s new import (`../../modules/settings/routes.dart`) matches its existing `../../modules/attendance/routes.dart` import exactly.

---

**Plan complete and saved to `docs/superpowers/plans/2026-09-20-phase6-rbac-console.md`.**
