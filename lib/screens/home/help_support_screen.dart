import 'package:flutter/material.dart';
import 'package:smart_kirana/utils/constants.dart';

class HelpSupportScreen extends StatefulWidget {
  static const String routeName = '/help-support';

  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Contact Us', 'FAQs'];
  int _expandedFaqIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Help & Support'),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -50,
                      top: -20,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.support_agent,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildContactTab(), _buildFaqTab()],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'How can we help you?',
            'Choose your preferred way to get in touch with our support team',
          ),
          const SizedBox(height: AppPadding.large),

          // Email Support
          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            description:
                'Send us an email and we\'ll get back to you within 24 hours',
            actionText: 'Send Email',
            onTap:
                () => _showContactDialog(
                  'Email Support',
                  'Please send your queries to mohdyusufr@gmail.com',
                  Icons.email,
                ),
            color: const Color(0xFF4285F4), // Google Blue
          ),

          // Phone Support
          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            description:
                'Call our customer service team for immediate assistance',
            actionText: 'Call Now',
            onTap:
                () => _showContactDialog(
                  'Phone Support',
                  'Please call us at +91 9084662330\nAvailable Mon-Sat, 9 AM - 6 PM',
                  Icons.phone,
                ),
            color: const Color(0xFF34A853), // Google Green
          ),

          // WhatsApp Support
          _buildContactCard(
            icon: Icons.chat_outlined,
            title: 'WhatsApp Support',
            description: 'Chat with our support team on WhatsApp',
            actionText: 'Chat Now',
            onTap:
                () => _showContactDialog(
                  'WhatsApp Support',
                  'Please message us on WhatsApp at +91 9084662330',
                  Icons.chat,
                ),
            color: const Color(0xFF25D366), // WhatsApp Green
          ),

          const SizedBox(height: AppPadding.large),

          // Additional Support Options
          _buildSectionHeader(
            'Additional Support',
            'More ways to get help with your orders and account',
          ),
          const SizedBox(height: AppPadding.medium),

          // Social Media Support
          _buildSocialMediaSupport(),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Frequently Asked Questions',
            'Find answers to common questions about our services',
          ),
          const SizedBox(height: AppPadding.medium),

          // FAQ Categories
          _buildFaqCategories(),
          const SizedBox(height: AppPadding.medium),

          // FAQ Items
          _buildFaqItem(
            0,
            'How do I track my order?',
            'You can track your order by going to the Order History section in your profile and selecting the specific order you want to track. You can also check the status of your order on the order details page.',
            Icons.local_shipping_outlined,
          ),

          _buildFaqItem(
            1,
            'What are the delivery charges?',
            'We charge a delivery fee of ₹40 for orders below ₹200. Orders above ₹200 qualify for free delivery.',
            Icons.payments_outlined,
          ),

          _buildFaqItem(
            2,
            'How can I cancel my order?',
            'You can cancel your order anytime before it is on its way to you. You can do this by going to the Order Details page and selecting the Cancel Order option.',
            Icons.cancel_outlined,
          ),

          _buildFaqItem(
            3,
            'What payment methods do you accept?',
            'We accept various payment methods including Cash on Delivery, Credit/Debit Cards, UPI, and Digital Wallets.',
            Icons.credit_card_outlined,
          ),

          _buildFaqItem(
            4,
            'How do I return a product?',
            'If you receive a damaged or incorrect product, please contact our customer support within 24 hours of delivery to initiate the return process.',
            Icons.assignment_return_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.medium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: Icon(icon, color: color, size: 30),
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
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small,
                    vertical: 6,
                  ),
                  child: Text(
                    actionText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaSupport() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect with us on social media',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            'Follow us for updates, offers, and quick support',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppPadding.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialButton(
                Icons.facebook,
                'Facebook',
                const Color(0xFF1877F2),
              ),
              _buildSocialButton(
                Icons.camera_alt_outlined,
                'Instagram',
                const Color(0xFFE1306C),
              ),
              _buildSocialButton(
                Icons.messenger_outline,
                'Twitter',
                const Color(0xFF1DA1F2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildFaqCategories() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFaqCategoryChip('All', isSelected: true),
          _buildFaqCategoryChip('Orders'),
          _buildFaqCategoryChip('Delivery'),
          _buildFaqCategoryChip('Payment'),
          _buildFaqCategoryChip('Returns'),
          _buildFaqCategoryChip('Account'),
        ],
      ),
    );
  }

  Widget _buildFaqCategoryChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: AppPadding.small),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? AppColors.primary : AppColors.background,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
      ),
    );
  }

  Widget _buildFaqItem(
    int index,
    String question,
    String answer,
    IconData icon,
  ) {
    final isExpanded = _expandedFaqIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedFaqIndex = isExpanded ? -1 : index;
            });
          },
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.small,
                        ),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppPadding.small),
                    Expanded(
                      child: Text(
                        question,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: AppPadding.small),
                  const Divider(),
                  const SizedBox(height: AppPadding.small),
                  Padding(
                    padding: const EdgeInsets.only(left: 40 + AppPadding.small),
                    child: Text(answer, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showContactDialog(
                  'Email Support',
                  'Please send your queries to mohdyusufr@gmail.com',
                  Icons.email,
                );
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Contact Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            title: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppPadding.small),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}
