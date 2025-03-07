import 'package:flutter/material.dart';
import 'package:smart_kirana/utils/constants.dart';

class HelpSupportScreen extends StatelessWidget {
  static const String routeName = '/help-support';

  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    'How can we help you?',
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    'Find answers to common questions or contact our support team',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppPadding.large),
            
            // Contact Options
            Text('Contact Us', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.medium),
            
            // Email Support
            _buildContactCard(
              context,
              icon: Icons.email,
              title: 'Email Support',
              description: 'Send us an email and we\'ll get back to you within 24 hours',
              actionText: 'Send Email',
              onTap: () {
                // Show a dialog with email information
                _showContactDialog(
                  context,
                  'Email Support',
                  'Please send your queries to support@smartkirana.com',
                );
              },
            ),
            
            // Phone Support
            _buildContactCard(
              context,
              icon: Icons.phone,
              title: 'Phone Support',
              description: 'Call our customer service team for immediate assistance',
              actionText: 'Call Now',
              onTap: () {
                // Show a dialog with phone information
                _showContactDialog(
                  context,
                  'Phone Support',
                  'Please call us at +91 9876543210\nAvailable Mon-Sat, 9 AM - 6 PM',
                );
              },
            ),
            
            // WhatsApp Support
            _buildContactCard(
              context,
              icon: Icons.chat,
              title: 'WhatsApp Support',
              description: 'Chat with our support team on WhatsApp',
              actionText: 'Chat Now',
              onTap: () {
                // Show a dialog with WhatsApp information
                _showContactDialog(
                  context,
                  'WhatsApp Support',
                  'Please message us on WhatsApp at +91 9876543210',
                );
              },
            ),
            
            const SizedBox(height: AppPadding.large),
            
            // FAQs
            Text('Frequently Asked Questions', style: AppTextStyles.heading3),
            const SizedBox(height: AppPadding.medium),
            
            _buildFaqItem(
              context,
              'How do I track my order?',
              'You can track your order by going to the Order History section in your profile and selecting the specific order you want to track.',
            ),
            
            _buildFaqItem(
              context,
              'What are the delivery charges?',
              'We charge a delivery fee of ₹40 for orders below ₹200. Orders above ₹200 qualify for free delivery.',
            ),
            
            _buildFaqItem(
              context,
              'How can I cancel my order?',
              'You can cancel your order within 30 minutes of placing it by going to the Order Details page and selecting the Cancel Order option.',
            ),
            
            _buildFaqItem(
              context,
              'What payment methods do you accept?',
              'We accept various payment methods including Cash on Delivery, Credit/Debit Cards, UPI, and Digital Wallets.',
            ),
            
            _buildFaqItem(
              context,
              'How do I return a product?',
              'If you receive a damaged or incorrect product, please contact our customer support within 24 hours of delivery to initiate the return process.',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppPadding.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppPadding.medium,
            0,
            AppPadding.medium,
            AppPadding.medium,
          ),
          child: Text(
            answer,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
  
  void _showContactDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
