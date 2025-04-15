import 'package:flutter/material.dart';
import 'package:smart_kirana/utils/constants.dart';

class AboutUsScreen extends StatelessWidget {
  static const String routeName = '/about-us';

  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo
            Center(
              child: Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.only(bottom: AppPadding.large),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: const Icon(
                  Icons.shopping_basket,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),

            // App Name
            Center(
              child: Text(
                'Smart Kirana',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),

            // App Version
            Center(
              child: Text(
                'Version 1.0.2',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: AppPadding.large),

            // About Section
            Text('About Smart Kirana', style: AppTextStyles.heading2),
            const SizedBox(height: AppPadding.small),
            const Text(
              'Smart Kirana is a modern provisional shopping app built to make your daily shopping easier, smarter, and more convenient. We offer a wide range of everyday essentials and household products, all delivered right to your doorstep with just a few taps.',
              style: AppTextStyles.bodyMedium,
            ),
            const Text(
              'Our app uses AI-powered recommendations to help you discover the right products faster, based on your preferences and shopping history.',
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: AppPadding.medium),

            // Mission Section
            Text('Our Mission', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.small),
            const Text(
              'To provide high-quality provisional items at affordable prices, backed by intelligent features, exceptional customer service, and fast, reliable delivery.',
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: AppPadding.medium),

            // Features Section
            Text('Key Features', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.small),
            _buildFeatureItem('Wide product selection'),
            _buildFeatureItem('Intelligent recommendations'),
            _buildFeatureItem('Fast and reliable delivery'),
            _buildFeatureItem('Secure payment options'),
            _buildFeatureItem('Easy order tracking'),
            _buildFeatureItem('Exclusive deals and discounts'),

            const SizedBox(height: AppPadding.medium),

            // Contact Section
            Text('Contact Us', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.small),
            _buildContactItem(Icons.email, 'mohdyusufr@gmail.com'),
            _buildContactItem(Icons.phone, '+91 9084662330'),
            _buildContactItem(
              Icons.location_on,
              '244402, Mohalla Badi Mandi, Town Bhojpur, District Moradabad',
            ),

            const SizedBox(height: AppPadding.large),

            // Copyright
            Center(
              child: Text(
                '© ${DateTime.now().year} Smart Kirana. All rights reserved.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          const SizedBox(width: AppPadding.small),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: AppPadding.small),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
