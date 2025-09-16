import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'providers/class_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/material_provider.dart';
import 'services/cache_service.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // No dotenv loading; keys are injected directly where needed
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://sknysmdgroapujgaszoy.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNrbnlzbWRncm9hcHVqZ2Fzem95Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwMDkwMTgsImV4cCI6MjA3MzU4NTAxOH0.hMwisjqVaJkTY5RGhW5p95RF07Msi9HQlwr7q4hl0Nc', // Replace with your Supabase anon key
  );
  
  // Check if we need to clear cache on app start (for debugging)
  // This can be useful if the app was force-closed during logout
  try {
    final hasCache = await CacheService.hasCache();
    if (hasCache) {
      print('Main: Found existing cache, checking if it should be cleared...');
      // You can add logic here to determine if cache should be cleared
      // For now, we'll just log the cache size
      final cacheSize = await CacheService.getCacheSize();
      print('Main: Cache size: $cacheSize bytes');
    }
  } catch (e) {
    print('Main: Error checking cache on startup: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ClassProvider>(
          create: (_) => ClassProvider(),
          update: (_, authProvider, classProvider) {
            print('Main: Updating ClassProvider with user: ${authProvider.currentUser?.name}');
            classProvider?.updateCurrentUser(authProvider.currentUser);
            return classProvider ?? ClassProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => MaterialProvider()),
      ],
      child: MaterialApp(
        title: 'Classroom',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4285F4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF4285F4),
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF4285F4),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper: isInitialized: ${authProvider.isInitialized}, isAuthenticated: ${authProvider.isAuthenticated}, isLoading: ${authProvider.isLoading}');
        print('AuthWrapper: Current user: ${authProvider.currentUser?.name} (${authProvider.currentUser?.email})');
        
        // Show loading screen while initializing
        if (!authProvider.isInitialized) {
          print('AuthWrapper: Showing loading screen');
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
                  SizedBox(height: 16),
                  Text(
                    'Initializing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show loading screen while authentication is in progress
        if (authProvider.isLoading) {
          print('AuthWrapper: Showing loading screen during auth operation');
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
                  SizedBox(height: 16),
                  Text(
                    'Please wait...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show main app if authenticated, otherwise show login
        if (authProvider.isAuthenticated) {
          print('AuthWrapper: User is authenticated, showing MainScreen');
          print('AuthWrapper: Current user: ${authProvider.currentUser?.name} (${authProvider.currentUser?.email})');
          
          // Clear force navigation flag if it was set
          if (authProvider.forceNavigation) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authProvider.clearForceNavigation();
            });
          }
          
          return const MainScreen();
        } else {
          print('AuthWrapper: User is not authenticated, showing LoginScreen');
          print('AuthWrapper: Current user: ${authProvider.currentUser?.name}');
          return const LoginScreen();
        }
      },
    );
  }
}
