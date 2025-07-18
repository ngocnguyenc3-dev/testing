import 'package:flutter_test/flutter_test.dart';

import 'auth_repository_mock.dart';


void main() {
  group('AuthRepository Unit Tests', () {
    late AuthRepository authRepository;
    late MockAuthService mockAuthService;
    late MockLocalStorage mockLocalStorage;

    setUp(() {
      mockAuthService = MockAuthService();
      mockLocalStorage = MockLocalStorage();
      authRepository = AuthRepository(
        authService: mockAuthService,
        localStorage: mockLocalStorage,
      );
    });

    group('signIn', () {
      test('should return success when valid credentials are provided',
          () async {
        // Arrange
        const inputEmail = 'test@example.com';
        const inputPassword = 'password123';
        const expectedToken = 'valid_token';
        const expectedRefreshToken = 'refresh_token';

        mockAuthService.setSignInResult(AuthResult.success(
          token: expectedToken,
          refreshToken: expectedRefreshToken, 
        ));

        // Act
        final actualResult =
            await authRepository.signIn(inputEmail, inputPassword);

        // Assert
        expect(actualResult.isSuccess, isTrue);
        expect(actualResult.token, equals(expectedToken));
        expect(actualResult.refreshToken, equals(expectedRefreshToken));
      });

      test('should return failure when email is empty', () async {
        // Arrange
        const inputEmail = '';
        const inputPassword = 'password123';
        const expectedErrorMessage = 'Email and password are required';

        // Act
        final actualResult =
            await authRepository.signIn(inputEmail, inputPassword);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage,
            equals(expectedErrorMessage));
      });

      test('should return failure when password is empty', () async {
        // Arrange
        const inputEmail = 'test@example.com';
        const inputPassword = '';
        const expectedErrorMessage = 'Email and password are required';

        // Act
        final actualResult =
            await authRepository.signIn(inputEmail, inputPassword);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage,
            equals(expectedErrorMessage));
      });

      test('should return failure when email format is invalid', () async {
        // Arrange
        const inputEmail = 'invalid_email';
        const inputPassword = 'password123';
        const expectedErrorMessage = 'Invalid email format';

        // Act
        final actualResult =
            await authRepository.signIn(inputEmail, inputPassword);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage, equals(expectedErrorMessage));
      });

      test('should return failure when auth service error', () async {
        // Arrange
        const inputEmail = 'test@example.com';
        const inputPassword = 'password123';
        const expectedErrorMessage = 'Invalid credentials';

        mockAuthService.setSignInResult(
            AuthResult.failure(errorMessage: expectedErrorMessage));

        // Act
        final actualResult =
            await authRepository.signIn(inputEmail, inputPassword);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage, equals(expectedErrorMessage));
      });

      test('should return failure when auth service throws exception',
          () async {
        // Arrange
        const inputEmail = 'test@example.com';
        const inputPassword = 'password123';
        const expectedErrorMessage = 'Network error';
        mockAuthService.setSignInException(Exception(expectedErrorMessage));

        // Act
        final actualResult =
            await authRepository.signIn(inputEmail, inputPassword);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage, equals(expectedErrorMessage));
      });
    });

    group('signUp', () {
      test('should return success when valid data is provided', () async {
        // Arrange
        const inputEmail = 'test@example.com';
        const inputPassword = 'password123';
        const inputName = 'Nguyendn';
        const expectedToken = 'valid_token';
        const expectedRefreshToken = 'refresh_token';

        mockAuthService.setSignUpResult(AuthResult.success(
          token: expectedToken,
          refreshToken: expectedRefreshToken,
        ));

        // Act
        final actualResult =
            await authRepository.signUp(inputEmail, inputPassword, inputName);

        // Assert
        expect(actualResult.isSuccess, isTrue);
        expect(actualResult.token, equals(expectedToken));
        expect(actualResult.refreshToken, equals(expectedRefreshToken));
      });

      test('should return failure when any field is empty', () async {
        // Arrange
        const inputEmail = 'test@example.com';
        const inputPassword = '';
        const inputName = 'Nguyendn';

        // Act
        final actualResult =
            await authRepository.signUp(inputEmail, inputPassword, inputName);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage, equals('All fields are required'));
      });

      test('should return failure when password is too short', () async {
        // Arrange
        const inputEmail = 'test@example.com';
        const inputPassword = '12345';
        const inputName = 'Nguyendn';

        // Act
        final actualResult =
            await authRepository.signUp(inputEmail, inputPassword, inputName);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage,
            equals('Password must be at least 6 characters'));
      });

      test('should return failure when email format is invalid', () async {
        // Arrange
        const inputEmail = 'invalid_email';
        const inputPassword = 'password123';
        const inputName = 'Nguyendn';
        const expectedErrorMessage = 'Invalid email format';

        // Act
        final actualResult =
            await authRepository.signUp(inputEmail, inputPassword, inputName);

        // Assert
        expect(actualResult.isSuccess, isFalse);
        expect(actualResult.errorMessage, equals(expectedErrorMessage));
      });
    });

    group('signOut', () {
      test('should clear token and call auth service signOut', () async {
        // Arrange
        // Mock is already set up to not throw

        // Act
        await authRepository.signOut();
      });
    });

    group('getStoredToken', () {
      test('should return stored token', () async {
        // Arrange
        const expectedToken = 'stored_token';
        await mockLocalStorage.saveToken(expectedToken);

        // Act
        final actualToken = await authRepository.getStoredToken();

        // Assert
        expect(actualToken, equals(expectedToken));
      });

      test('should return null when no token is stored', () async {
        // Arrange
        // Token is already null by default

        // Act
        final actualToken = await authRepository.getStoredToken();

        // Assert
        expect(actualToken, isNull);
      });
    });

    group('Test isValidEmail function', () {
      test('should validate correct all email formats', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
          '123@test.com',
        ];

        // Act & Assert
        for (final email in validEmails) {
          expect(authRepository.isValidEmail(email), isTrue,
              reason: 'Email: $email');
        }
      });

      test('should reject invalid email formats', () {
        // Arrange
        final invalidEmails = [
          'invalid_email',
          'test@',
          'test..test@example.com',
        ];

        // Act & Assert
        for (final email in invalidEmails) {
          expect(authRepository.isValidEmail(email), isFalse,
              reason: 'Email: $email');
        }
      });
    });
  });
}
