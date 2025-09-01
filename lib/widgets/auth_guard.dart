import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool showLoading;

  const AuthGuard({
    super.key,
    required this.child,
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading screen while initializing
        if (!authProvider.isInitialized && showLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF4285F4),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          // Redirect to login screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          });
          
          // Show loading while redirecting
          return const Scaffold(
            backgroundColor: Color(0xFF4285F4),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated, show the protected content
        return child;
      },
    );
  }
}
