import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/models/expense.dart';
import 'package:final_project/models/users.dart';
import 'package:final_project/services/auth_service.dart';
import 'package:final_project/services/expense_service.dart';
import 'package:final_project/views/dashboard_view.dart';
import 'package:final_project/widgets/auth_gate.dart';

class TestUser extends Fake implements User {
  @override
  String get uid => 'test-user';
  @override
  String get email => 'person@example.com';
}

class TestAuthService extends AuthService {
  final states = StreamController<User?>.broadcast();
  int registrations = 0;
  int logins = 0;
  String? submittedEmail;
  String? submittedPassword;
  Object? failure;
  Completer<void>? pending;

  @override
  Stream<User?> authStateChanges() => states.stream;

  @override
  User? get currentUser => null;

  Future<void> authenticate(String email, String password) async {
    submittedEmail = email;
    submittedPassword = password;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    states.add(TestUser());
  }

  @override
  Future<void> signIn(String email, String password) async {
    logins++;
    await authenticate(email, password);
  }

  @override
  Future<AppUser> register(String email, String password) async {
    registrations++;
    await authenticate(email, password);
    return AppUser(uid: 'test-user', email: email, createdAt: DateTime(2026));
  }

  @override
  Future<void> signOut() async => states.add(null);
}

class TestExpenseService extends ExpenseService {
  @override
  Stream<List<Expense>> watchExpenses(String userId) =>
      Stream<List<Expense>>.value(const []);

  @override
  Future<void> addExpense(String userId, Expense expense) async {}

  @override
  Future<void> deleteExpense(String userId, String id) async {}
}

void main() {
  late TestAuthService auth;

  setUp(() => auth = TestAuthService());
  tearDown(() => auth.states.close());

  Future<void> openApp(WidgetTester tester, {bool signedIn = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(authService: auth, expenseService: TestExpenseService()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.states.add(signedIn ? TestUser() : null);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String text) async {
    final button = find.widgetWithText(FilledButton, text);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('login validates fields before contacting Firebase', (
    tester,
  ) async {
    await openApp(tester);
    await submit(tester, 'Log in');
    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(auth.logins, 0);
  });

  testWidgets('register validates confirmation, then signs in and logs out', (
    tester,
  ) async {
    await openApp(tester);
    await tester.ensureVisible(find.text('New here? Create an account'));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  person@example.com  ');
    await tester.enterText(fields.at(1), ' password123 ');
    await tester.enterText(fields.at(2), 'different');
    await submit(tester, 'Create account');
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.registrations, 0);
    await tester.enterText(fields.at(2), ' password123 ');
    await submit(tester, 'Create account');
    expect(auth.registrations, 1);
    expect(auth.submittedEmail, 'person@example.com');
    expect(auth.submittedPassword, ' password123 ');
    expect(find.byType(DashboardView), findsOneWidget);
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
    expect(find.byType(DashboardView), findsNothing);
  });

  testWidgets('existing sessions open the dashboard', (tester) async {
    await openApp(tester, signedIn: true);
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('Firebase errors keep the user on login and allow retry', (
    tester,
  ) async {
    auth.failure = FirebaseAuthException(code: 'invalid-credential');
    await openApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await submit(tester, 'Log in');
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(find.byType(DashboardView), findsNothing);
    auth.failure = null;
    await submit(tester, 'Log in');
    expect(auth.logins, 2);
    expect(find.byType(DashboardView), findsOneWidget);
  });

  test('Android configuration errors have an actionable message', () {
    final error = FirebaseAuthException(
      code: 'unknown',
      message: 'An internal error occurred. [ CONFIGURATION_NOT_FOUND ]',
    );

    expect(
      authErrorMessage(error),
      contains('Firebase Console > Authentication > Sign-in method'),
    );
  });

  testWidgets('pending requests disable submission and page switching', (
    tester,
  ) async {
    auth.pending = Completer<void>();
    await openApp(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    expect(auth.logins, 1);
    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DashboardView), findsOneWidget);
  });
}
