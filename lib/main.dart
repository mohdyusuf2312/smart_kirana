import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/firebase_options.dart';
import 'package:smart_kirana/providers/address_provider.dart';
import 'package:smart_kirana/providers/admin_provider.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/providers/cart_provider.dart';
import 'package:smart_kirana/providers/order_provider.dart';
import 'package:smart_kirana/providers/payment_provider.dart';
import 'package:smart_kirana/providers/product_provider.dart';
import 'package:smart_kirana/providers/recommendation_provider.dart';
import 'package:smart_kirana/services/admin_initialization_service.dart';
import 'package:smart_kirana/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_kirana/screens/admin/category_management_screen.dart';
import 'package:smart_kirana/screens/admin/expiring_soon_screen.dart';
import 'package:smart_kirana/screens/admin/low_stock_screen.dart';
import 'package:smart_kirana/screens/admin/order_management_screen.dart';
import 'package:smart_kirana/screens/admin/product_import_screen.dart';
import 'package:smart_kirana/screens/admin/product_management_screen.dart';
import 'package:smart_kirana/screens/admin/recommendation_management_screen.dart';
import 'package:smart_kirana/screens/admin/user_management_screen.dart';
import 'package:smart_kirana/screens/auth/email_verification_screen.dart';
import 'package:smart_kirana/screens/auth/forgot_password_screen.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/auth/reset_password_confirm_screen.dart';
import 'package:smart_kirana/screens/auth/signup_screen.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';
import 'package:smart_kirana/screens/home/home_wrapper.dart';
import 'package:smart_kirana/screens/home/about_us_screen.dart';
import 'package:smart_kirana/screens/home/address_screen.dart';
import 'package:smart_kirana/screens/home/cart_screen.dart';
import 'package:smart_kirana/screens/home/edit_profile_screen.dart';
import 'package:smart_kirana/screens/home/help_support_screen.dart';
import 'package:smart_kirana/screens/home/location_picker_screen.dart';
import 'package:smart_kirana/screens/orders/order_detail_screen.dart';
import 'package:smart_kirana/screens/orders/order_history_screen.dart';
import 'package:smart_kirana/screens/orders/order_tracking_screen.dart';
import 'package:smart_kirana/screens/payment/payment_failure_screen.dart';
import 'package:smart_kirana/screens/payment/payment_screen.dart';
import 'package:smart_kirana/screens/payment/payment_success_screen.dart';
import 'package:smart_kirana/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Silently continue without .env file
    // In a production app, use a proper logging framework
  }

  // Initialize default admin user
  try {
    final adminInitService = AdminInitializationService();
    await adminInitService.initializeDefaultAdmin();
  } catch (e) {
    // Log error but continue with app startup
    // debugPrint('Failed to initialize admin user: $e');
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
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AddressProvider>(
          create:
              (context) => AddressProvider(
                authProvider: Provider.of<AuthProvider>(context, listen: false),
              ),
          update:
              (context, authProvider, previous) =>
                  AddressProvider(authProvider: authProvider),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          ProductProvider,
          CartProvider
        >(
          create:
              (context) => CartProvider(
                authProvider: Provider.of<AuthProvider>(context, listen: false),
                productProvider: Provider.of<ProductProvider>(
                  context,
                  listen: false,
                ),
              ),
          update:
              (context, authProvider, productProvider, previous) =>
                  CartProvider(
                    authProvider: authProvider,
                    productProvider: productProvider,
                  ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create:
              (context) => OrderProvider(
                authProvider: Provider.of<AuthProvider>(context, listen: false),
              ),
          update:
              (context, authProvider, previous) =>
                  OrderProvider(authProvider: authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create:
              (context) => PaymentProvider(
                authProvider: Provider.of<AuthProvider>(context, listen: false),
              ),
          update:
              (context, authProvider, previous) =>
                  PaymentProvider(authProvider: authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (context) {
            final provider = AdminProvider(
              authProvider: Provider.of<AuthProvider>(context, listen: false),
            );
            // Initialize with empty data to prevent null errors
            // debugPrint('Creating AdminProvider instance');
            return provider;
          },
          update: (context, authProvider, previous) {
            // debugPrint('Updating AdminProvider with new AuthProvider');
            // Preserve previous state if available
            if (previous != null && authProvider.user?.role == 'ADMIN') {
              // debugPrint('Reusing previous AdminProvider state');
              return previous;
            }
            return AdminProvider(authProvider: authProvider);
          },
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            surfaceContainerHighest: AppColors.background,
            error: AppColors.error,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          textTheme: TextTheme(
            displayLarge: AppTextStyles.heading1,
            displayMedium: AppTextStyles.heading2,
            displaySmall: AppTextStyles.heading3,
            bodyLarge: AppTextStyles.bodyLarge,
            bodyMedium: AppTextStyles.bodyMedium,
            bodySmall: AppTextStyles.bodySmall,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium,
              vertical: AppPadding.medium,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              borderSide: const BorderSide(
                color: AppColors.textSecondary,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withAlpha(76), // 0.3 * 255 = 76
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              borderSide: const BorderSide(color: AppColors.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              elevation: 0,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              // Don't set minimumSize to allow flexible TextButton sizes
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
            ),
          ),
        ),
        home: const HomeWrapper(),
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          SignupScreen.routeName: (context) => const SignupScreen(),
          ForgotPasswordScreen.routeName:
              (context) => const ForgotPasswordScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          OrderHistoryScreen.routeName: (context) => const OrderHistoryScreen(),
          '/cart': (context) => const CartScreen(),
          '/address': (context) => const AddressScreen(),
          EditProfileScreen.routeName: (context) => const EditProfileScreen(),
          HelpSupportScreen.routeName: (context) => const HelpSupportScreen(),
          AboutUsScreen.routeName: (context) => const AboutUsScreen(),
          // Admin Routes
          AdminDashboardScreen.routeName:
              (context) => const AdminDashboardScreen(),
          ProductManagementScreen.routeName:
              (context) => const ProductManagementScreen(),
          ProductImportScreen.routeName:
              (context) => const ProductImportScreen(),
          CategoryManagementScreen.routeName:
              (context) => const CategoryManagementScreen(),
          OrderManagementScreen.routeName:
              (context) => const OrderManagementScreen(),
          LowStockScreen.routeName: (context) => const LowStockScreen(),
          ExpiringSoonScreen.routeName: (context) => const ExpiringSoonScreen(),
          UserManagementScreen.routeName:
              (context) => const UserManagementScreen(),
          RecommendationManagementScreen.routeName:
              (context) => const RecommendationManagementScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == EmailVerificationScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder:
                  (context) => EmailVerificationScreen(email: args['email']),
            );
          } else if (settings.name == OrderDetailScreen.routeName) {
            final orderId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            );
          } else if (settings.name == OrderTrackingScreen.routeName) {
            final orderId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(orderId: orderId),
            );
          } else if (settings.name == PaymentScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder:
                  (context) => PaymentScreen(
                    orderId: args['orderId'], // Can be null for new flow
                    amount: args['amount'],
                    cartItems: args['cartItems'], // For new flow
                    subtotal: args['subtotal'], // For new flow
                    deliveryFee: args['deliveryFee'], // For new flow
                    deliveryAddress: args['deliveryAddress'], // For new flow
                  ),
            );
          } else if (settings.name == PaymentSuccessScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder:
                  (context) => PaymentSuccessScreen(
                    orderId: args['orderId'],
                    paymentId: args['paymentId'],
                    amount: args['amount'],
                    method: args['method'],
                    isNewFlow: args['isNewFlow'] ?? false,
                  ),
            );
          } else if (settings.name == PaymentFailureScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder:
                  (context) => PaymentFailureScreen(
                    orderId: args['orderId'],
                    paymentId: args['paymentId'],
                    amount: args['amount'],
                    method: args['method'],
                    errorMessage: args['errorMessage'],
                  ),
            );
          } else if (settings.name == ResetPasswordConfirmScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ResetPasswordConfirmScreen(arguments: args),
            );
          } else if (settings.name == LocationPickerScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder:
                  (context) => LocationPickerScreen(
                    initialLocation: args?['initialLocation'],
                  ),
            );
          }
          return null;
        },
      ),
    );
  }
}
