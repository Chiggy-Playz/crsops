// Challans and clients screens, driven through the real router with fake
// repositories, at a phone size and a wide window.
import 'package:crs_ops/app_router.dart';
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/clients/clients_section.dart';
import 'package:crs_ops/core/clients/models/client.dart';
import 'package:crs_ops/core/clients/models/client_address.dart';
import 'package:crs_ops/core/clients/providers/client_providers.dart';
import 'package:crs_ops/core/data/shared_preferences_provider.dart';
import 'package:crs_ops/core/sections/app_sections_provider.dart';
import 'package:crs_ops/core/theme/app_theme.dart';
import 'package:crs_ops/modules/challans/challans_section.dart';
import 'package:crs_ops/modules/challans/financial_year.dart';
import 'package:crs_ops/modules/challans/models/challan_direction.dart';
import 'package:crs_ops/modules/challans/providers/challan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/clients/fakes/fake_client_repository.dart';
import 'fakes/fake_challan_repository.dart';

const _phone = Size(400, 900);
// Tall, so the whole challan form fits without scrolling.
const _wide = Size(1400, 1800);

ClientAddress _address(String clientId, String label, String stateCode) =>
    ClientAddress(
      addressId: '$clientId-a1',
      clientId: clientId,
      label: label,
      versionId: '$clientId-v1',
      version: 1,
      nameOnChallan: clientId.toUpperCase(),
      address: 'Somewhere',
      stateCode: stateCode,
      stateName: FakeClientRepository.stateName(stateCode),
    );

List<Client> _clients() => [
  Client(
    id: 'client-1',
    name: 'Vega Corporate',
    createdAt: DateTime(2026),
    addresses: [_address('client-1', 'Main', '07')],
  ),
  Client(
    id: 'client-2',
    name: 'Offshoot Agency',
    createdAt: DateTime(2026),
    addresses: [_address('client-2', 'Sector 4', '06')],
  ),
];

final _today = DateTime.now();
final _thisYear = financialYearOf(_today);

class _Harness {
  _Harness(this.router, this.challans, this.clients);

  final GoRouter router;
  final FakeChallanRepository challans;
  final FakeClientRepository clients;
}

Future<_Harness> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final challanRepo = FakeChallanRepository(
    seed: [
      fakeChallan(id: 'o12', number: 12),
      fakeChallan(
        id: 'o11',
        number: 11,
        clientId: 'client-2',
        clientName: 'Offshoot Agency',
        firstItem: 'HP PRINTER',
        receivedOn: DateTime(_today.year, _today.month, _today.day),
      ),
      fakeChallan(id: 'i3', number: 3, direction: ChallanDirection.inward),
      fakeChallan(
        id: 'o10',
        number: 10,
        addressVersion: 1,
        latestAddressVersion: 2,
      ),
    ],
  );
  final clientRepo = FakeClientRepository(seed: _clients());

  final container = ProviderContainer(
    overrides: [
      appSectionsProvider.overrideWithValue([challansSection, clientsSection]),
      sharedPreferencesProvider.overrideWithValue(prefs),
      sessionProvider.overrideWithValue(
        const AsyncData(
          AppSession(
            userId: 'u',
            email: 'boss@x.com',
            role: AppRole.superadmin,
            moduleAccess: {},
          ),
        ),
      ),
      challanRepositoryProvider.overrideWithValue(challanRepo),
      clientRepositoryProvider.overrideWithValue(clientRepo),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildAppTheme(brightness: Brightness.light),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(router, challanRepo, clientRepo);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('the list shows one direction, switches, and searches', (
    tester,
  ) async {
    await _pumpApp(tester, _phone);

    expect(find.text('Challans'), findsWidgets);
    expect(find.text(financialYearLabel(_thisYear)), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Offshoot Agency'), findsOneWidget);
    expect(find.text('3'), findsNothing);

    await tester.tap(find.text('Inward'));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('12'), findsNothing);

    await tester.tap(find.text('Outward'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'printer');
    await tester.pumpAndSettle();
    expect(find.text('Offshoot Agency'), findsOneWidget);
    expect(find.text('Vega Corporate'), findsNothing);
  });

  testWidgets('the not-received filter hides received challans', (
    tester,
  ) async {
    await _pumpApp(tester, _phone);
    expect(find.text('11'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Not received'));
    await tester.pumpAndSettle();
    expect(find.text('11'), findsNothing);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('a challan page shows it and saves follow-ups', (tester) async {
    final app = await _pumpApp(tester, _phone);

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(
      find.text('Outward challan ${challanNumberLabel(12, _thisYear)}'),
      findsOneWidget,
    );
    expect(find.text('DELL LAPTOP'), findsOneWidget);
    expect(find.text('Delivered by'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Digitally signed'), 200);
    await tester.tap(find.text('Digitally signed'));
    await tester.pumpAndSettle();
    expect(app.challans.signed['o12'], isTrue);

    await tester.scrollUntilVisible(find.text('History'), 200);
    expect(find.text('Created'), findsOneWidget);
  });

  testWidgets('saving an empty form shows what is missing', (tester) async {
    final app = await _pumpApp(tester, _wide);

    await tester.tap(find.text('New outward challan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Pick the client'), findsOneWidget);
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a description'), findsOneWidget);
    expect(app.challans.created, isEmpty);
  });

  testWidgets('a new challan is saved with the picked client and items', (
    tester,
  ) async {
    final app = await _pumpApp(tester, _wide);

    await tester.tap(find.text('New outward challan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Client'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main · Delhi'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Delivered by'), 'Ramesh');
    await tester.enterText(_field('Description'), 'Mouse');
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Description').last, 'Keyboard');
    // The new row's quantity, which starts at 1.
    await tester.enterText(_field('1').last, '3');
    await tester.pumpAndSettle();
    expect(find.text('Total 4'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final draft = app.challans.created.single;
    expect(draft.direction, ChallanDirection.outward);
    expect(draft.addressId, 'client-1-a1');
    expect(draft.handledByName, 'Ramesh');
    expect(draft.items.map((i) => i.description), ['Mouse', 'Keyboard']);
    expect(draft.items.map((i) => i.quantity), [1, 3]);
    // Opens the new challan.
    expect(app.router.state.matchedLocation, '/challans/new-1');
  });

  testWidgets('items can be reordered and removed', (tester) async {
    final app = await _pumpApp(tester, _wide);

    await tester.tap(find.text('New outward challan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Client'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main · Delhi'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Delivered by'), 'Ramesh');
    await tester.enterText(_field('Description'), 'First');
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Description').last, 'Second');
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Description').last, 'Third');

    await tester.tap(find.byTooltip('Item 3 options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move up'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Item 1 options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(app.challans.created.single.items.map((i) => i.description), [
      'Third',
      'Second',
    ]);
  });

  testWidgets('the form opens beside the list and asks before losing edits', (
    tester,
  ) async {
    final app = await _pumpApp(tester, _wide);

    await tester.tap(find.text('New outward challan'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Description'), 'Mouse');
    // The list is still there; picking a challan would lose the typing.
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.router.state.matchedLocation, '/challans/new');
    expect(find.text('Mouse'), findsOneWidget);

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(app.router.state.matchedLocation, '/challans/o12');
  });

  testWidgets('an untouched form closes without asking', (tester) async {
    final app = await _pumpApp(tester, _wide);

    await tester.tap(find.text('New outward challan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(app.router.state.matchedLocation, '/challans');
  });

  testWidgets('cancelling can bring the goods back in', (tester) async {
    final app = await _pumpApp(tester, _phone);

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel challan'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Reason (optional)'),
      'Wrong client',
    );
    await tester.tap(find.text('Bring the goods back in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel challan'));
    await tester.pumpAndSettle();

    final call = app.challans.cancelled.single;
    expect(call.id, 'o12');
    expect(call.reason, 'Wrong client');
    expect(call.createReturn, isTrue);
    expect(find.text('Cancelled'), findsWidgets);
    // A cancelled challan can't be edited.
    final edit = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.edit_outlined),
    );
    expect(edit.onPressed, isNull);
  });

  testWidgets('bringing goods back is off unless ticked', (tester) async {
    final app = await _pumpApp(tester, _phone);

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel challan'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel challan'));
    await tester.pumpAndSettle();

    expect(app.challans.cancelled.single.createReturn, isFalse);
    expect(app.challans.cancelled.single.reason, isNull);
  });

  testWidgets('editing offers the latest address only when it changed', (
    tester,
  ) async {
    final app = await _pumpApp(tester, _wide);

    app.router.go('/challans/o10');
    await tester.pumpAndSettle();
    expect(find.textContaining('has been edited since'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit challan'));
    await tester.pumpAndSettle();
    expect(find.text("Use the client's latest details"), findsOneWidget);
    await tester.tap(find.text("Use the client's latest details"));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(app.challans.updated['o10']!.useLatestAddress, isTrue);

    app.router.go('/challans/o12');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit challan'));
    await tester.pumpAndSettle();
    expect(find.text("Use the client's latest details"), findsNothing);
  });

  testWidgets("a client's page lists its challans", (tester) async {
    final app = await _pumpApp(tester, _wide);

    app.router.go('/clients/client-1');
    await tester.pumpAndSettle();

    expect(find.text('New outward challan'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('11'), findsNothing);
  });

  testWidgets('a new challan from a client page starts with its address', (
    tester,
  ) async {
    final app = await _pumpApp(tester, _wide);

    app.router.go('/clients/client-2');
    await tester.pumpAndSettle();
    await tester.tap(find.text('New outward challan'));
    await tester.pumpAndSettle();

    expect(find.text('Sector 4 · Haryana'), findsOneWidget);
  });

  testWidgets('search groups results by client', (tester) async {
    final app = await _pumpApp(tester, _wide);

    await tester.tap(find.byTooltip('Search all years'));
    await tester.pumpAndSettle();
    expect(app.router.state.matchedLocation, '/challans/search');

    final searchBox = find.descendant(
      of: find.byType(SearchBar).last,
      matching: find.byType(TextField),
    );
    await tester.enterText(searchBox, 'printer');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(app.challans.searches.last.text, 'printer');
    expect(find.text('Offshoot Agency · 1'), findsOneWidget);

    await tester.tap(find.text('Outward and inward'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inward').last);
    await tester.pumpAndSettle();
    expect(app.challans.searches.last.direction, ChallanDirection.inward);

    // Filtering by client goes through the picker's Apply.
    await tester.tap(find.text('All clients'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Vega Corporate'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(app.challans.searches.last.clientIds, ['client-1']);
    expect(find.widgetWithText(InputChip, 'Vega Corporate'), findsOneWidget);

    // Results can be exported.
    expect(find.byTooltip('Export'), findsOneWidget);
  });

  testWidgets('a new client copies its name into "Name on challan"', (
    tester,
  ) async {
    final app = await _pumpApp(tester, _wide);

    app.router.go('/clients/new');
    await tester.pumpAndSettle();
    await tester.enterText(_field('Client name'), 'Acme');
    await tester.pumpAndSettle();

    final nameOnChallan = tester.widget<TextFormField>(
      _field('Name on challan'),
    );
    expect(nameOnChallan.controller!.text, 'Acme');
  });
}
