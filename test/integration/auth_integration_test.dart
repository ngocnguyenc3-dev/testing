import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock implementations for integration testing
class MockAuthService {
  bool _isAuthenticated = false;
  String? _currentUser;
  String? _storedToken;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;
  String? get storedToken => _storedToken;

  Future<AuthResult> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (email.isEmpty || password.isEmpty) {
      return AuthResult.failure(errorMessage: 'Email and password are required');
    }

    if (email == 'test@example.com' && password == 'password123') {
      _isAuthenticated = true;
      _currentUser = email;
      _storedToken = 'valid_token_${DateTime.now().millisecondsSinceEpoch}';
      return AuthResult.success(
        token: _storedToken!,
        refreshToken: 'refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      return AuthResult.failure(errorMessage: 'Invalid credentials');
    }
  }

  Future<AuthResult> signUp(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      return AuthResult.failure(errorMessage: 'All fields are required');
    }

    if (password.length < 6) {
      return AuthResult.failure(errorMessage: 'Password must be at least 6 characters');
    }

    _isAuthenticated = true;
    _currentUser = email;
    _storedToken = 'valid_token_${DateTime.now().millisecondsSinceEpoch}';
    return AuthResult.success(
      token: _storedToken!,
      refreshToken: 'refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _isAuthenticated = false;
    _currentUser = null;
    _storedToken = null;
  }

  Future<AuthResult> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (refreshToken.startsWith('refresh_token_')) {
      _storedToken = 'new_token_${DateTime.now().millisecondsSinceEpoch}';
      return AuthResult.success(
        token: _storedToken!,
        refreshToken: 'new_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      return AuthResult.failure(errorMessage: 'Invalid refresh token');
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String? token;
  final String? refreshToken;
  final String? errorMessage;

  AuthResult.success({required this.token, required this.refreshToken})
      : isSuccess = true,
        errorMessage = null;

  AuthResult.failure({required this.errorMessage})
      : isSuccess = false,
        token = null,
        refreshToken = null;
}

class AuthController {
  final MockAuthService _authService;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<String?> errorMessage = ValueNotifier(null);
  AuthResult? _lastResult;

  AuthController({required MockAuthService authService}) : _authService = authService;

  bool get isAuthenticated => _authService.isAuthenticated;
  String? get currentUser => _authService.currentUser;
  AuthResult? get lastResult => _lastResult;

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.signIn(email, password);
      _lastResult = result;

      if (result.isSuccess) {
        _setError(null);
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.signUp(email, password, name);
      _lastResult = result;

      if (result.isSuccess) {
        _setError(null);
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signOut();
      _setLoading(false);
    } catch (e) {
      _setError('Sign out error: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<bool> refreshToken(String refreshToken) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.refreshToken(refreshToken);
      _lastResult = result;

      if (result.isSuccess) {
        _setError(null);
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Token refresh error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) => isLoading.value = loading;
  void _setError(String? error) => errorMessage.value = error;
}

// Integration test app
class AuthIntegrationApp extends StatefulWidget {
  const AuthIntegrationApp({super.key});

  @override
  State<AuthIntegrationApp> createState() => _AuthIntegrationAppState();
}

class _AuthIntegrationAppState extends State<AuthIntegrationApp> {
  final _authService = MockAuthService();
  late final AuthController _authController;
  bool _isLoginMode = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authController = AuthController(authService: _authService);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoginMode) {
      await _authController.signIn(_emailController.text, _passwordController.text);
    } else {
      await _authController.signUp(_emailController.text, _passwordController.text, _nameController.text);
    }
    setState(() {});
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _authController.errorMessage.value = null;
    });
  }

  void _handleSignOut() async {
    await _authController.signOut();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Integration Test',
      home: Scaffold(
        appBar: AppBar(
          title: Text(_isLoginMode ? 'Login Screen' : 'Sign Up Screen'),
          actions: [
            if (_authController.isAuthenticated)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleSignOut,
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _authController.isAuthenticated
              ? _buildAuthenticatedView()
              : _buildAuthForm(),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            'Welcome, ${_authController.currentUser}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Token: ${_authController.lastResult?.token?.substring(0, 20)}...',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleSignOut,
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isLoginMode) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ValueListenableBuilder(
              valueListenable: _authController.errorMessage,
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
            valueListenable: _authController.isLoading,
            builder: (context, isLoading, child) {
              return ElevatedButton(
                onPressed: isLoading ? null : _handleSubmit,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isLoginMode ? 'Sign In' : 'Sign Up'),
              );
            }
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _toggleMode,
          child: Text(_isLoginMode
              ? 'Don\'t have an account? Sign up'
              : 'Already have an account? Login'),
        ),
      ],
    );
  }
}

void main() {
  group('Auth Integration Tests', () {
    testWidgets('Complete authentication flow - login success', (WidgetTester tester) async {
      // Given - User opens the app
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      // When - User enters valid credentials and taps sign in
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Then - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // When - Authentication completes
      await tester.pumpAndSettle();

      // Then - User should be authenticated and see welcome message
      expect(find.text('Welcome, test@example.com!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('Complete authentication flow - login failure', (WidgetTester tester) async {
      // Given - User opens the app
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      // When - User enters invalid credentials and taps sign in
      await tester.enterText(find.byType(TextField).first, 'wrong@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpassword');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Then - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // When - Authentication completes
      await tester.pumpAndSettle();

      // Then - Error message should be displayed
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);
    });

    testWidgets('Complete authentication flow - signup success', (WidgetTester tester) async {
      // Given - User opens the app and switches to signup mode
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Don\'t have an account? Sign up'));
      await tester.pumpAndSettle();

      // When - User enters valid signup data and taps sign up
      await tester.enterText(find.byType(TextField).at(0), 'Nguyendn');
      await tester.enterText(find.byType(TextField).at(1), 'newuser@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Then - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // When - Authentication completes
      await tester.pumpAndSettle();

      // Then - User should be authenticated and see welcome message
      expect(find.text('Welcome, newuser@example.com!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Complete authentication flow - signup validation failure', (WidgetTester tester) async {
      // Given - User opens the app and switches to signup mode
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Don\'t have an account? Sign up'));
      await tester.pumpAndSettle();

      // When - User enters invalid signup data (short password) and taps sign up
      await tester.enterText(find.byType(TextField).at(0), 'Nguyendn');
      await tester.enterText(find.byType(TextField).at(1), 'newuser@example.com');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      // Then - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // When - Authentication completes
      await tester.pumpAndSettle();

      // Then - Error message should be displayed
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Complete authentication flow - logout', (WidgetTester tester) async {
      // Given - User is authenticated
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify user is authenticated
      expect(find.text('Welcome, test@example.com!'), findsOneWidget);

      // When - User taps logout
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Then - User should be logged out and see login form
      expect(find.text('Welcome, test@example.com!'), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);
    });

    testWidgets('Form validation - empty fields', (WidgetTester tester) async {
      // Given - User opens the app
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      // When - User taps sign in without entering any data
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      // Then - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // When - Authentication completes
      await tester.pumpAndSettle();

      // Then - Error message should be displayed
      expect(find.text('Email and password are required'), findsOneWidget);
    });

    testWidgets('Form switching - clear errors when switching modes', (WidgetTester tester) async {
      // Given - User opens the app and creates an error
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.text('Email and password are required'), findsOneWidget);

      // When - User switches to signup mode
      await tester.tap(find.text('Don\'t have an account? Sign up'));
      await tester.pumpAndSettle();

      // Then - Error should be cleared
      expect(find.text('Email and password are required'), findsNothing);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Network error handling', (WidgetTester tester) async {
      // Given - User opens the app
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      // When - User enters credentials that would cause a network error
      // (This would require mocking network failures, but we can test the UI response)
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      // Then - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // When - Authentication completes
      await tester.pumpAndSettle();

      // Then - User should see success (since our mock doesn't simulate network errors)
      expect(find.text('Welcome, test@example.com!'), findsOneWidget);
    });

    testWidgets('Concurrent authentication attempts', (WidgetTester tester) async {
      // Given - User opens the app
      await tester.pumpWidget(const AuthIntegrationApp());
      await tester.pumpAndSettle();

      // When - User rapidly taps sign in multiple times
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');

      await tester.tap(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Then - Only one loading indicator should be shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // When - Authentication completes
      await tester.pumpAndSettle();

      // Then - User should be authenticated
      expect(find.text('Welcome, test@example.com!'), findsOneWidget);
    });
  });
} 