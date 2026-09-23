import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/features/admin/widgets/admin_gate.dart';
import 'package:modiin4u/features/auth/models/user_model.dart';
import 'package:modiin4u/features/auth/providers/auth_provider.dart';

/// The admin area is a security boundary that cannot be exercised on a device
/// until sign-in works end to end, so it is pinned here instead.
void main() {
  const marker = Text('CONTROL CENTER', textDirection: TextDirection.ltr);

  UserModel person({required bool isAdmin}) => UserModel(
    id: 'ecd6b4f6-0000-4000-8000-000000000001',
    name: 'Test',
    phone: '',
    role: isAdmin ? UserRole.admin : UserRole.user,
    createdAt: DateTime(2026),
  );

  Future<void> pump(WidgetTester tester, List<Override> overrides) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: AdminGate(child: marker)),
      ),
    );
  }

  testWidgets('a resident is turned away', (tester) async {
    await pump(tester, [
      authProvider.overrideWith((ref) => _StubAuth(person(isAdmin: false))),
      authRestoringProvider.overrideWith((ref) => false),
    ]);
    await tester.pump();

    expect(find.text('CONTROL CENTER'), findsNothing);
    expect(find.text('אין לך גישה לאזור הניהול'), findsOneWidget);
  });

  testWidgets('an administrator is let through', (tester) async {
    await pump(tester, [
      authProvider.overrideWith((ref) => _StubAuth(person(isAdmin: true))),
      authRestoringProvider.overrideWith((ref) => false),
    ]);
    await tester.pump();

    expect(find.text('CONTROL CENTER'), findsOneWidget);
  });

  testWidgets('waits rather than deciding while the session is restoring', (
    tester,
  ) async {
    await pump(tester, [
      authProvider.overrideWith((ref) => _StubAuth(null)),
      authRestoringProvider.overrideWith((ref) => true),
    ]);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('CONTROL CENTER'), findsNothing);
  });
}

/// Stands in for [AuthNotifier] without reaching Supabase.
class _StubAuth extends StateNotifier<UserModel?> implements AuthNotifier {
  _StubAuth(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
