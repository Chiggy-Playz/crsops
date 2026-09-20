import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/router/redirect_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeRedirect', () {
    test('loading session redirects to /loading from any other route', () {
      final result = computeRedirect(
        sessionValue: const AsyncLoading(),
        currentLocation: '/',
      );
      expect(result, '/loading');
    });

    test('loading session does not redirect if already on /loading', () {
      final result = computeRedirect(
        sessionValue: const AsyncLoading(),
        currentLocation: '/loading',
      );
      expect(result, isNull);
    });

    test('signed out (null session) redirects to /sign-in', () {
      final result = computeRedirect(
        sessionValue: const AsyncData(null),
        currentLocation: '/',
      );
      expect(result, '/sign-in');
    });

    test('signed out already on /sign-in does not redirect', () {
      final result = computeRedirect(
        sessionValue: const AsyncData(null),
        currentLocation: '/sign-in',
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
        currentLocation: '/',
      );
      expect(result, '/unauthorized');
    });

    test('signed in with a role on /sign-in redirects to /', () {
      const session = AppSession(
        userId: 'u1',
        email: 'a@x.com',
        role: AppRole.admin,
        moduleAccess: {},
      );
      final result = computeRedirect(
        sessionValue: AsyncData(session),
        currentLocation: '/sign-in',
      );
      expect(result, '/');
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
        currentLocation: '/',
      );
      expect(result, isNull);
    });

    test('error session redirects to /sign-in', () {
      final result = computeRedirect(
        sessionValue: AsyncError('boom', StackTrace.empty),
        currentLocation: '/',
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

      test('admin on a superadmin route bounces to /unauthorized', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/settings/roles',
          ),
          '/unauthorized',
        );
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/employees/event-types',
          ),
          '/unauthorized',
        );
      });

      test('superadmin passes superadmin routes', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(superadmin),
            currentLocation: '/settings/roles',
          ),
          isNull,
        );
      });

      test('non-admin on an admin route bounces to /unauthorized', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(employeeWithAccess),
            currentLocation: '/attendance/shift-defaults',
          ),
          '/unauthorized',
        );
      });

      test('admin passes admin routes and unguarded routes', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/settings/module-access',
          ),
          isNull,
        );
        expect(
          computeRedirect(
            sessionValue: const AsyncData(admin),
            currentLocation: '/reports',
          ),
          isNull,
        );
      });

      test('calendar requires attendance module access', () {
        expect(
          computeRedirect(
            sessionValue: const AsyncData(employeeWithAccess),
            currentLocation: '/',
          ),
          isNull,
        );
        expect(
          computeRedirect(
            sessionValue: const AsyncData(employeeWithoutAccess),
            currentLocation: '/',
          ),
          '/unauthorized',
        );
      });
    });
  });
}
