import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/auth/signup_screen.dart';
import 'package:smart_kirana/screens/home/about_us_screen.dart';
import 'package:smart_kirana/screens/home/address_screen.dart';
import 'package:smart_kirana/screens/home/edit_profile_screen.dart';
import 'package:smart_kirana/screens/home/help_support_screen.dart';
import 'package:smart_kirana/screens/home/home_screen.dart';
import 'package:smart_kirana/screens/orders/order_history_screen.dart';
import 'package:smart_kirana/utils/constants.dart';
import 'package:smart_kirana/widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return authProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : user == null
        ? _buildNotLoggedIn(context)
        : _buildProfileContent(context, user, authProvider);
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    // Check if we're on web platform for enhanced guest experience
    final isWeb =
        Theme.of(context).platform != TargetPlatform.android &&
        Theme.of(context).platform != TargetPlatform.iOS;

    if (isWeb) {
      // Enhanced guest experience for web
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guest Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withAlpha(128),
                      child: Icon(
                        Icons.person_outline,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppPadding.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Guest!',
                            style: AppTextStyles.heading2,
                          ),
                          const SizedBox(height: AppPadding.small),
                          Text(
                            'Browse products and add to cart',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Login for personalized experience',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.medium),

            // Login/Register Options
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Column(
                children: [
                  _buildProfileOption(
                    context,
                    icon: Icons.login,
                    title: 'Login to Your Account',
                    textColor: AppColors.primary,
                    onTap: () {
                      Navigator.pushNamed(context, LoginScreen.routeName);
                    },
                  ),
                  const Divider(height: 1),
                  _buildProfileOption(
                    context,
                    icon: Icons.person_add,
                    title: 'Create New Account',
                    onTap: () {
                      Navigator.pushNamed(context, SignupScreen.routeName);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.medium),

            // Guest Options
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Column(
                children: [
                  _buildProfileOption(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildProfileOption(
                    context,
                    icon: Icons.info_outline,
                    title: 'About Us',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.large),

            // App Version
            Center(
              child: Text(
                'App Version 1.0.0',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Original mobile experience
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 100,
              color: AppColors.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: AppPadding.medium),
            Text('You are not logged in', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.small),
            Text(
              'Please login to view your profile',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppPadding.large),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
              child: CustomButton(
                text: 'Login',
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    LoginScreen.routeName,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProfileContent(
    BuildContext context,
    UserModel user,
    AuthProvider authProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppPadding.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTextStyles.heading2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppPadding.small),
                        Text(
                          user.email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.phone,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppPadding.medium),

          // Profile Options
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Column(
              children: [
                _buildProfileOption(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'My Addresses',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.medium),

          // Account Options
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Column(
              children: [
                if (user.role == 'ADMIN')
                  Column(
                    children: [
                      _buildProfileOption(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Panel',
                        textColor: AppColors.primary,
                        onTap: () {
                          // Use MaterialPageRoute with a fresh provider context
                          // debugPrint(
                          //   'Navigating to admin dashboard from profile',
                          // );

                          // Get providers
                          // final adminProvider = Provider.of<AdminProvider>(
                          //   context,
                          //   listen: false,
                          // );
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          // debugPrint(
                          //   'Admin provider in profile: ${adminProvider.hashCode}',
                          // );
                          // debugPrint(
                          //   'Auth provider in profile: ${authProvider.hashCode}',
                          // );
                          // debugPrint('User role: ${authProvider.user?.role}');

                          // Check if user is admin before navigating
                          if (authProvider.user?.role == 'ADMIN') {
                            // debugPrint(
                            //   'User confirmed as admin, proceeding to dashboard',
                            // );

                            // Use named route navigation instead of MaterialPageRoute
                            Navigator.of(
                              context,
                            ).pushNamed(AdminDashboardScreen.routeName);
                          } else {
                            // debugPrint('User is not admin, showing error');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You do not have admin privileges',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                _buildProfileOption(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  context,
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutUsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: AppColors.error,
                  onTap: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      // Check if we're on web platform
                      final isWeb =
                          Theme.of(context).platform !=
                              TargetPlatform.android &&
                          Theme.of(context).platform != TargetPlatform.iOS;

                      if (isWeb) {
                        // On web, navigate to home screen (allows guest access)
                        Navigator.pushReplacementNamed(
                          context,
                          HomeScreen.routeName,
                        );
                      } else {
                        // On mobile, navigate to login screen (requires authentication)
                        Navigator.pushReplacementNamed(
                          context,
                          LoginScreen.routeName,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.large),

          // App Version
          Center(
            child: Text(
              'App Version 1.0.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.medium,
          vertical: AppPadding.medium,
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.textPrimary, size: 24),
            const SizedBox(width: AppPadding.medium),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary.withAlpha(128),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
