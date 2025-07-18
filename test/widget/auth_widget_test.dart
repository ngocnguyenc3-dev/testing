import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
class Constants {
  static const String validEmail = 'test@example.com';
  static const String validPassword = 'password123';
}
// Mock controller for testing
class MockAuthController {
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<String?> errorMessage = ValueNotifier(null);
  ValueNotifier<bool> isAuthenticated = ValueNotifier(false);

  void setLoading(bool loading) => isLoading.value = loading;
  void setError(String? error) => errorMessage.value = error;
  void setAuthenticated(bool authenticated) => isAuthenticated.value = authenticated;

  Future<bool> signIn(String email, String password) async {
    setLoading(true);
    setError(null);
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (email.isEmpty || password.isEmpty) {
      setError('Email and password are required');
      setLoading(false);
      return false;
    }

    if (email == Constants.validEmail && password == Constants.validPassword) {
      setAuthenticated(true);
      setLoading(false);
      return true;
    } else {
      setError('Invalid credentials');
      setLoading(false);
      return false;
    }
  }
}

// Simple login form widget
class LoginForm extends StatefulWidget {
  final MockAuthController controller;
  final VoidCallback? onSuccess;

  const LoginForm({
    super.key,
    required this.controller,
    this.onSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.controller.signIn(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success && widget.onSuccess != null) {
        widget.onSuccess!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ValueListenableBuilder(
                valueListenable: widget.controller.errorMessage,
                builder: (context, errorMessage, child) {
                  return Text(
                    errorMessage ?? '',
                    style: TextStyle(color: Colors.red.shade700),
                  );
                }
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ValueListenableBuilder(
              valueListenable: widget.controller.isLoading,
              builder: (context, isLoading, child) {
                return ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign In'),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Auth Widget Tests', () {
    group('LoginForm Widget Tests', () {
      testWidgets('should display login form with all fields', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(controller: mockController),
            ),
          ),
        );

        // Assert
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should show validation error for empty email', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(controller: mockController),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Sign In'));
        await tester.pump();

        // Assert
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('should show loading indicator during authentication and remove it after authentication', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(controller: mockController),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextFormField).first, Constants.validEmail);
        await tester.enterText(find.byType(TextFormField).last, Constants.validPassword);
        await tester.tap(find.text('Sign In'));
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Sign In'), findsNothing);

        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Sign In'), findsOneWidget);
      });

      testWidgets('should show error message when authentication fails', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(controller: mockController),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextFormField).first, 'wrong@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Invalid credentials'), findsOneWidget);
      });

      testWidgets('should call onSuccess callback when authentication succeeds', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();
        bool successCallbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(
                controller: mockController,
                onSuccess: () => successCallbackCalled = true,
              ),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Assert
        expect(successCallbackCalled, isTrue);
      });

      testWidgets('should disable button during loading', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(controller: mockController),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextFormField).first, Constants.validEmail);
        await tester.enterText(find.byType(TextFormField).last, Constants.validPassword);
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        // Assert
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
        await tester.pumpAndSettle();
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle rapid form submissions', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(controller: mockController),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextFormField).first, Constants.validEmail);
        await tester.enterText(find.byType(TextFormField).last, Constants.validPassword);
        
        // Rapid taps
        await tester.tap(find.text('Sign In'));
        await tester.tap(find.text('Sign In'));
        await tester.tap(find.text('Sign In'));
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle();
      });

      testWidgets('should handle empty form submission', (WidgetTester tester) async {
        // Arrange
        final mockController = MockAuthController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoginForm(controller: mockController),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Sign In'));
        await tester.pump();

        // Assert
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
        expect(mockController.isLoading.value, isFalse);
      });
    });
  });
} 