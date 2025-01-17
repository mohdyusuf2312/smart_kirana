import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_kirana/models/user_model.dart';
import 'package:smart_kirana/providers/auth_provider.dart';
import 'package:smart_kirana/screens/auth/login_screen.dart';
import 'package:smart_kirana/screens/home/address_screen.dart';
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
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              },
            ),
          ),
        ],
      ),
    );
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
                    // TODO: Implement edit profile screen
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
                _buildProfileOption(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    // TODO: Implement help & support screen
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  context,
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () {
                    // TODO: Implement about us screen
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
                      Navigator.pushReplacementNamed(
                        context,
                        LoginScreen.routeName,
                      );
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
