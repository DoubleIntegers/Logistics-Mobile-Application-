import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'customer/customer_dashboard_screen.dart';
import 'driver/driver_dashboard_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        // Show loading spinner during init / loading
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not authenticated → Login
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        final user = auth.currentUser!;

        // RBAC: Route by role
        if (user.isCustomer) {
          return const CustomerDashboardScreen();
        } else if (user.isDriver) {
          return const DriverDashboardScreen();
        }

        // Fallback for unknown roles
        return Scaffold(
          body: Center(
            child: Text('Unknown role: ${user.role}'),
          ),
        );
      },
    );
  }
}