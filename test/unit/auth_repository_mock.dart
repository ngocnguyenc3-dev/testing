// Mock implementations for testing
abstract class AuthService {
  Future<AuthResult> signIn(String email, String password);
  Future<AuthResult> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<AuthResult> refreshToken(String refreshToken);
}

abstract class LocalStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<void> saveRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<void> clearRefreshToken();
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

// Simple mock implementations
class MockAuthService implements AuthService {
  AuthResult? _signInResult;
  AuthResult? _signUpResult;
  Exception? _signInException;
  Exception? _signUpException;

  void setSignInResult(AuthResult result) => _signInResult = result;
  void setSignUpResult(AuthResult result) => _signUpResult = result;
  void setSignInException(Exception exception) =>
      _signInException = exception;

  @override
  Future<AuthResult> signIn(String email, String password) async {
    if (_signInResult != null) return _signInResult!;
    if (_signInException != null) throw _signInException!;
    return AuthResult.failure(errorMessage: 'Mock not configured');
  }

  @override
  Future<AuthResult> signUp(String email, String password, String name) async {
    if (_signUpResult != null) return _signUpResult!;
    if (_signUpException != null) throw _signUpException!;
    return AuthResult.failure(errorMessage: 'Mock not configured');
  }

  @override
  Future<void> signOut() async {
  }

  @override
  Future<AuthResult> refreshToken(String refreshToken) async {
    return AuthResult.failure(errorMessage: 'Not implemented');
  }
}

class MockLocalStorage implements LocalStorage {
  String? _storedToken;
  String? _storedRefreshToken;

  @override
  Future<void> saveToken(String token) async {
    _storedToken = token;
  }

  @override
  Future<String?> getToken() async {
    return _storedToken;
  }

  @override
  Future<void> clearToken() async {
    _storedToken = null;
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    _storedRefreshToken = refreshToken;
  }

  @override
  Future<String?> getRefreshToken() async { 
    return _storedRefreshToken;
  }

  @override
  Future<void> clearRefreshToken() async {
    _storedRefreshToken = null;
  }
}

class AuthRepository {
  final AuthService _authService;
  final LocalStorage _localStorage;

  AuthRepository({
    required AuthService authService,
    required LocalStorage localStorage,
  })  : _authService = authService,
        _localStorage = localStorage;

  Future<AuthResult> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return AuthResult.failure(
            errorMessage: 'Email and password are required');
      }

      if (!isValidEmail(email)) {
        return AuthResult.failure(errorMessage: 'Invalid email format');
      }

      final result = await _authService.signIn(email, password);

      if (result.isSuccess && result.token != null) {
        await _localStorage.saveToken(result.token!);
      }

      return result;
    } catch (e) {
      return AuthResult.failure(errorMessage: 'Network error: ${e.toString()}');
    }
  }

  Future<AuthResult> signUp(String email, String password, String name) async {
    try {
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return AuthResult.failure(errorMessage: 'All fields are required');
      }

      if (!isValidEmail(email)) {
        return AuthResult.failure(errorMessage: 'Invalid email format');
      }

      if (password.length < 6) {
        return AuthResult.failure(
            errorMessage: 'Password must be at least 6 characters');
      }

      final result = await _authService.signUp(email, password, name);

      if (result.isSuccess && result.token != null) {
        await _localStorage.saveToken(result.token!);
      }

      return result;
    } catch (e) {
      return AuthResult.failure(errorMessage: 'Network error: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await _localStorage.clearToken();
    } catch (e) {
      // Log error but don't throw
      print('Sign out error: ${e.toString()}');
    }
  }

  Future<String?> getStoredToken() async {
    return await _localStorage.getToken();
  }

  bool isValidEmail(String email) {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);
  }
}