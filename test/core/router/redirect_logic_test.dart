import 'package:crs_ops/app_sections.dart';
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/router/redirect_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeRedirect', () {
    test('loading session redirects to /loading from any other route', () {
      final result = computeRedirect(
        sessionValue: const AsyncLoading(),
        currentLocation: '/attendance/calendar',
        sections: allSections,
      );
      expect(result, '/loading');
    });

    test('loading session does not redirect if already on /loading', () {
      final result = computeRedirect(
        sessionValue: const AsyncLoading(),
        currentLocation: '/loading',
        sections: allSections,
      );
      expect(result, isNull);
    });

    test('signed out (null session) redirects to /sign-in', () {
      final result = computeRedirect(
        sessionValue: const AsyncData(null),
        currentLocation: '/attendance/calendar',
        sections: allSections,
      );
      expect(result, '/sign-in');
    });

    test('signed out already on /sign-in does not redirect', () {
      final result = computeRedirect(
        sessionValue: const AsyncData(null),
        currentLocation: '/sign-in',
        sections: allSections,
      );
      expect(result, isNull);
    });

    test('signed in with no role redirects to /unauthorized', () {
      const session = AppSession(
        userId: 'u1',
        email: 'a@x.com',
        role: null,
        moduleAccess: {},
      );
      final result = computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: '/attendance/calendar',
        sections: allSections,
      );
      expect(result, '/unauthorized');
    });

    test('signed in with a role on /sign-in redirects to the calendar', () {
      const session = AppSession(
        userId: 'u1',
        email: 'a@x.com',
        role: AppRole.admin,
        moduleAccess: {},
      );
      final result = computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: '/sign-in',
        sections: allSections,
      );
      expect(result, '/attendance/calendar');
    });

    test('signed in with a role on an app route does not redirect', () {
      const session = AppSession(
        userId: 'u1',
        email: 'a@x.com',
        role: AppRole.admin,
        moduleAccess: {},
      );
      final result = computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: '/attendance/calendar',
        sections: allSections,
      );
      expect(result, isNull);
    });

    test('error session redirects to /sign-in', () {
      final result = computeRedirect(
        sessionValue: AsyncError('boom', StackTrace.empty),
        currentLocation: '/attendance/calendar',
        sections: allSections,
      );
      expect(result, '/sign-in');
    });

    group('module and role guards', () {
      const admin = AppSession(
        userId: 'u1',
        email: 'a@x.com',
        role: AppRole.admin,
        moduleAccess: {},
      );
      const superadmin = AppSession(
        userId: 'u2',
        email: 's@x.com',
        role: AppRole.superadmin,
        moduleAccess: {},
      );
      const employeeWithAccess = AppSession(
        userId: 'u3',
        email: 'e@x.com',
        role: AppRole.employee,
        moduleAccess: {'attendance'},
      );
      const employeeWithoutAccess = AppSession(
        userId: 'u4',
        email: 'f@x.com',
        role: AppRole.employee,
        moduleAccess: {},
      );

      test('admin on a superadmin route bounces to their landing page', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/settings/roles',
            sections: allSections,
          ),
          '/attendance/calendar',
        );
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/settings/employees/event-types',
            sections: allSections,
          ),
          '/attendance/calendar',
        );
      });

      test('superadmin passes superadmin routes', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(superadmin),
            currentLocation: '/settings/roles',
            sections: allSections,
          ),
          isNull,
        );
      });

      test('non-admin on an admin route bounces to their landing page', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(employeeWithAccess),
            currentLocation: '/settings/attendance/shift-defaults',
            sections: allSections,
          ),
          '/attendance/calendar',
        );
      });

      test('admin passes admin routes and unguarded routes', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/settings/module-access',
            sections: allSections,
          ),
          isNull,
        );
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/attendance/reports',
            sections: allSections,
          ),
          isNull,
        );
      });

      test('calendar requires attendance module access', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(employeeWithAccess),
            currentLocation: '/attendance/calendar',
            sections: allSections,
          ),
          isNull,
        );
        expect(
          computeRedirect(
            sessionValue: const AsyncData(employeeWithoutAccess),
            currentLocation: '/attendance/calendar',
            sections: allSections,
          ),
          '/no-modules',
        );
      });

      test(
        'reports and attendance-day require attendance module access too',
        () {
          expect(
            computeRedirect(
              sessionValue: const AsyncData(employeeWithAccess),
              currentLocation: '/attendance/reports',
              sections: allSections,
            ),
            isNull,
          );
          expect(
            computeRedirect(
              sessionValue: const AsyncData(employeeWithoutAccess),
              currentLocation: '/attendance/reports',
              sections: allSections,
            ),
            '/no-modules',
          );
          expect(
            computeRedirect(
              sessionValue: const AsyncData(employeeWithoutAccess),
              currentLocation: '/attendance/2024-06-03',
              sections: allSections,
            ),
            '/no-modules',
          );
        },
      );
    });

    group('landing', () {
      const staffWithAccess = AppSession(
        userId: 'u3',
        email: 'e@x.com',
        role: AppRole.employee,
        moduleAccess: {'attendance'},
      );
      const staffWithoutAccess = AppSession(
        userId: 'u4',
        email: 'f@x.com',
        role: AppRole.employee,
        moduleAccess: {},
      );

      String? redirect(AppSession session, String location) => computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: location,
        sections: allSections,
      );

      test('lands on the first section the user can access', () {
        expect(redirect(staffWithAccess, '/sign-in'), '/attendance/calendar');
        expect(redirect(staffWithAccess, '/'), '/attendance/calendar');
      });

      test(
        'a role without any module lands on /no-modules instead of looping',
        () {
          // Previously: calendar -> /unauthorized -> calendar -> ... until
          // go_router's redirect limit.
          expect(redirect(staffWithoutAccess, '/sign-in'), '/no-modules');
          expect(redirect(staffWithoutAccess, '/unauthorized'), '/no-modules');
          expect(redirect(staffWithoutAccess, '/no-modules'), isNull);
        },
      );

      test('settings is open to everyone but never a landing spot', () {
        expect(redirect(staffWithoutAccess, '/settings'), isNull);
        expect(landingLocation(staffWithoutAccess, allSections), '/no-modules');
      });

      test('a user granted access moves off /no-modules', () {
        expect(
          redirect(staffWithAccess, '/no-modules'),
          '/attendance/calendar',
        );
      });

      test('a hidden section\'s URL lands the user back home', () {
        expect(redirect(staffWithAccess, '/employees'), '/attendance/calendar');
        expect(
          redirect(staffWithAccess, '/employees/abc'),
          '/attendance/calendar',
        );
      });
    });
  });

  group('AppSection.owns', () {
    final section = allSections.firstWhere((s) => s.pathPrefix == '/employees');

    test('owns its prefix and everything under it', () {
      expect(section.owns('/employees'), isTrue);
      expect(section.owns('/employees/abc/edit'), isTrue);
    });

    test('does not own a path that merely starts with the same letters', () {
      expect(section.owns('/employeesx'), isFalse);
    });
  });
}
