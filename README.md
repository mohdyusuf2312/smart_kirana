# Smart Kirana - Digitizing the Provisional Store with AI

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue.svg)](https://flutter.dev/)
[![AI](https://img.shields.io/badge/AI-Powered%20Recommendations-green.svg)](https://firebase.google.com/)

## 📱 Project Overview

Smart Kirana is a revolutionary Flutter-based mobile and web application that transforms traditional provisional stores (Kirana stores) into modern, AI-powered digital marketplaces. The application bridges the gap between conventional neighborhood stores and modern e-commerce platforms by providing intelligent product recommendations, seamless order management, and comprehensive business analytics.

### 🎯 Project Vision
To digitize and modernize the traditional Kirana store ecosystem in India by leveraging artificial intelligence, mobile technology, and cloud computing to enhance customer experience and business efficiency.

### 🚀 Problem Statement
Traditional Kirana stores face challenges in:
- Manual inventory management
- Limited customer reach
- Lack of data-driven insights
- Inefficient order processing
- Poor customer engagement
- Absence of personalized shopping experiences

### 💡 Solution Approach
Smart Kirana addresses these challenges through:
- **AI-Driven Recommendations**: Personalized product suggestions based on user behavior
- **Digital Inventory Management**: Real-time stock tracking and low-stock alerts
- **Multi-Platform Accessibility**: Android, iOS, and Web support
- **Location-Based Services**: GPS tracking for order delivery and customer convenience
- **Comprehensive Analytics**: Business insights and performance metrics
- **Seamless Payment Integration**: Multiple payment options including COD and online payments

## 🌟 Key Features & Functionalities

### 👥 Customer Features
- **🔐 Authentication System**:
  - Secure email/password login with Firebase Authentication
  - One-time email verification on registration
  - Password recovery via Firebase email reset
  - Role-based access control (Customer/Admin)

- **🛍️ Product Discovery & Shopping**:
  - Browse products by categories with advanced search functionality
  - Product filtering by price, category, and availability
  - Detailed product views with images, descriptions, and pricing
  - Real-time stock availability checking

- **🤖 AI-Powered Smart Recommendations**:
  - Personalized product suggestions based on purchase history
  - Popular products recommendations
  - Category-based recommendations
  - Expiring products alerts for better deals

- **🛒 Shopping Cart Management**:
  - Persistent cart storage in Firestore
  - Real-time cart updates and synchronization
  - Cart summary display across all screens
  - Guest cart functionality with login integration

- **📦 Order Management**:
  - Complete order lifecycle from placement to delivery
  - Order history and detailed order tracking
  - Multiple delivery address management
  - Order status updates and notifications

- **📍 Location Services**:
  - GPS-based automatic location detection
  - Multiple address management
  - Real-time order tracking with Google Maps
  - Delivery agent location tracking

- **💳 Payment Integration**:
  - Cash on Delivery (COD) option
  - Simulated online payment processing
  - Payment status tracking
  - Invoice generation and download

- **👤 Profile Management**:
  - Comprehensive user profile editing
  - Address book management
  - Order history access
  - Account settings and preferences

### 🔧 Admin Features
- **📊 Analytics Dashboard**:
  - Real-time business metrics and KPIs
  - Revenue tracking and analysis
  - User engagement statistics
  - Order trends and patterns
  - Interactive charts and graphs using FL Chart

- **📦 Product Management**:
  - Full CRUD operations for products and categories
  - Bulk product import via CSV files
  - Product image management with Firebase Storage
  - Inventory tracking and stock management
  - Product popularity and featured status control

- **⚠️ Inventory Control**:
  - Low stock alerts and notifications
  - Expiry date tracking for perishable items
  - Automated stock level monitoring
  - Inventory reports and analytics

- **🚚 Order Management**:
  - Order status updates and tracking
  - Delivery coordination and management
  - Order fulfillment workflow
  - Customer communication tools

- **👥 User Management**:
  - Customer account administration
  - User role management
  - Account verification status
  - User activity monitoring

- **🎯 Recommendation Engine Management**:
  - AI-driven product recommendation configuration
  - Popular products management
  - Featured products selection
  - Recommendation performance analytics

- **📄 Invoice & Reporting**:
  - Automated invoice creation and PDF export
  - Sales reports and analytics
  - Customer purchase history
  - Business performance reports

## 🏗️ Technical Architecture & System Design

### 🎨 Frontend Architecture
- **Framework**: Flutter 3.7.2+ (Cross-platform development)
- **Programming Language**: Dart SDK
- **State Management**: Provider pattern for reactive state management
- **UI Framework**: Material Design with custom theming and responsive layouts
- **Navigation**: Named routes with route guards for authentication
- **Platform Support**: Android, iOS, and Web with platform-specific optimizations

### ☁️ Backend & Cloud Services
- **Authentication**: Firebase Authentication (Email/Password, Email Verification)
- **Database**: Cloud Firestore (NoSQL document database)
- **Storage**: Firebase Storage (Image and file storage)
- **Hosting**: Firebase Hosting for web deployment
- **Security**: Firebase Security Rules for data protection
- **Analytics**: Firebase Analytics for user behavior tracking

### 🗺️ Third-Party Integrations
- **Maps & Location**:
  - Google Maps Platform for interactive maps
  - Route Optimization API for delivery tracking
  - Geolocator for GPS positioning
  - Geocoding for address resolution
- **Payment Processing**: Simulated payment gateway integration
- **Charts & Analytics**: FL Chart for data visualization
- **File Handling**: CSV import/export for bulk operations

### 📊 Database Schema & Data Models

#### Firestore Collections Structure:
```
📊 Smart Kirana Database Schema:

├── 👥 users/
│   ├── id (Document ID)
│   ├── name: String
│   ├── email: String
│   ├── phone: String
│   ├── addresses: Array<UserAddress>
│   ├── isVerified: Boolean
│   ├── createdAt: Timestamp
│   ├── lastLogin: Timestamp
│   └── role: String (CUSTOMER/ADMIN)
│
├── 📦 products/
│   ├── id (Document ID)
│   ├── name: String
│   ├── description: String
│   ├── price: Number
│   ├── discountPrice: Number (optional)
│   ├── imageUrl: String
│   ├── categoryId: String
│   ├── categoryName: String
│   ├── stock: Number
│   ├── unit: String
│   ├── isPopular: Boolean
│   ├── isFeatured: Boolean
│   └── expiryDate: Timestamp (optional)
│
├── 🏷️ categories/
│   ├── id (Document ID)
│   ├── name: String
│   └── imageUrl: String
│
├── 🛒 orders/
│   ├── id (Document ID)
│   ├── userId: String
│   ├── items: Array<OrderItem>
│   ├── subtotal: Number
│   ├── deliveryFee: Number
│   ├── discount: Number
│   ├── totalAmount: Number
│   ├── orderDate: Timestamp
│   ├── status: String (pending/confirmed/shipped/delivered/cancelled)
│   ├── deliveryAddress: Map
│   ├── paymentMethod: String
│   ├── deliveryNotes: String (optional)
│   ├── estimatedDeliveryTime: Timestamp (optional)
│   ├── userName: String
│   ├── deliveryLatitude: Number (optional)
│   ├── deliveryLongitude: Number (optional)
│   ├── currentLatitude: Number (optional)
│   ├── currentLongitude: Number (optional)
│   ├── deliveryAgentName: String (optional)
│   ├── deliveryAgentPhone: String (optional)
│   ├── paymentStatus: String
│   ├── paymentId: String (optional)
│   └── transactionId: String (optional)
│
├── 🔑 admins/
│   ├── id (Document ID - same as user ID)
│   └── role: String (ADMIN)
│
├── 💳 payments/
│   ├── id (Document ID)
│   ├── orderId: String
│   ├── userId: String
│   ├── amount: Number
│   ├── status: String (pending/completed/failed/refunded)
│   ├── method: String (cod/online/card/upi)
│   ├── timestamp: Timestamp
│   ├── transactionId: String (optional)
│   └── gatewayResponse: Map (optional)
│
└── 🎯 recommendations/
    ├── id (Document ID)
    ├── userId: String
    ├── productId: String
    ├── score: Number
    ├── type: String (user_based/popular/category/expiring)
    └── createdAt: Timestamp
```

### 🔧 System Architecture Patterns
- **MVC Pattern**: Model-View-Controller separation
- **Repository Pattern**: Data access abstraction
- **Provider Pattern**: State management and dependency injection
- **Service Layer**: Business logic separation
- **Factory Pattern**: Object creation and initialization

## 🎨 Design System & UI/UX

### 🎨 Color Palette
The application follows a nature-inspired color scheme that reflects the traditional Kirana store aesthetic:

- **Primary**: #6C9A8B (Calm Green) - Trust and reliability
- **Secondary**: #F4A259 (Earthy Orange) - Energy and warmth
- **Accent**: #DDA15E (Natural Gold) - Premium and quality
- **Background**: #F1F1E8 (Light Olive) - Comfort and ease
- **Surface**: #FFFFFF (White) - Cleanliness and simplicity
- **Text Primary**: #2D2D2D - High readability
- **Text Secondary**: #6B6B6B - Supporting information
- **Success**: #A3B18A - Positive actions
- **Error**: #E63946 - Alerts and warnings

### 📱 Responsive Design Principles
- **Mobile-First Approach**: Optimized for mobile devices with progressive enhancement
- **Adaptive Layouts**: Dynamic grid systems based on screen size
- **Touch-Friendly**: Minimum 44px touch targets for accessibility
- **Cross-Platform Consistency**: Unified experience across Android, iOS, and Web

### 🎯 User Experience (UX) Features
- **Intuitive Navigation**: Bottom navigation for mobile, sidebar for web
- **Progressive Disclosure**: Information revealed as needed
- **Feedback Systems**: Loading states, success/error messages
- **Accessibility**: Screen reader support, high contrast options
- **Performance Optimization**: Lazy loading, image optimization

## 🚀 Getting Started & Installation

### 📋 Prerequisites & System Requirements

#### Development Environment:
- **Flutter SDK**: 3.7.2 or higher
- **Dart SDK**: Compatible with Flutter version
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA
- **Git**: For version control

#### Platform-Specific Requirements:
- **Android**: Android Studio, Android SDK (API level 21+)
- **iOS**: Xcode 12+, iOS 11+ (macOS required)
- **Web**: Chrome browser for testing

#### Cloud Services:
- **Firebase Project**: With Authentication, Firestore, and Storage enabled
- **Google Maps API**: For location services and mapping
- **Google Cloud Platform**: Account for Firebase services

### 🛠️ Installation & Setup Guide

#### 1. **Repository Setup**
```bash
# Clone the repository
git clone <repository-url>
cd smart_kirana

# Verify Flutter installation
flutter doctor

# Install dependencies
flutter pub get
```

#### 2. **Firebase Configuration**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init
```

**Firebase Services to Enable:**
- Authentication (Email/Password provider)
- Cloud Firestore (Database)
- Firebase Storage (File storage) (Optional)
- Firebase Hosting (Web deployment) (Optional)

**Configuration Files:**
- Download `google-services.json` for Android → `android/app/`
- Download `GoogleService-Info.plist` for iOS → `ios/Runner/`
- Update `firebase_options.dart` with your project configuration

#### 3. **Environment Configuration**
Create `.env` file in the project root:
```env
# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
Also add GOOGLE_MAPS_API_KEY in api script in index.html file
location of index.html file
```Root_folder\web\index.html

# Firebase Configuration (if needed)
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_api_key

# Other API Keys
RAZORPAY_KEY_ID=your_razorpay_key_id (Optional)
RAZORPAY_KEY_SECRET=your_razorpay_key_secret (Optional)
```

#### 4. **Google Maps Setup**
- Enable Google Maps SDK for Android/iOS/JavaScript
- Enable Places API, Geocoding API, Directions API
- Add API key to platform-specific configuration files

#### 5. **Build and Run**
```bash
# Run on Android
flutter run -d android

# Run on iOS (macOS only)
flutter run -d ios

# Run on Web
flutter run -d chrome

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

### 🔧 Development Setup

#### Code Editor Configuration:
- Install Flutter and Dart plugins
- Configure code formatting (dartfmt)
- Set up debugging configurations
- Enable hot reload for faster development

#### Testing Setup:
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate test coverage
flutter test --coverage
```

## 📱 Platform Support & Compatibility

| Platform | Status | Features | Performance | Notes |
|----------|--------|----------|-------------|-------|
| **Android** | ✅ Full Support | All features including maps, location, camera | Optimized | API Level 21+ |
| **iOS** | ✅ Full Support | All features including maps, location, camera | Optimized | iOS 11+ |
| **Web** | ✅ Enhanced | All features with responsive design | Good | Chrome, Firefox, Safari |

### 📊 Performance Metrics
- **App Size**: ~15MB (Android APK)
- **Cold Start**: <3 seconds
- **Hot Reload**: <1 second
- **Memory Usage**: <100MB average
- **Battery Optimization**: Background location optimized

## 🔐 Default Admin Access & User Roles

### Default Administrator Account
For testing and initial setup:
- **Email**: mohdyusufr@gmail.com
- **Password**: yusuf11
- **Role**: ADMIN
- **Permissions**: Full system access

### User Role Hierarchy
1. **ADMIN**: Full system access, analytics, user management
2. **CUSTOMER**: Shopping, orders, profile management
3. **GUEST**: Limited browsing (Web only)

### Security Features
- **Email Verification**: Required for new accounts
- **Password Reset**: Firebase-powered email reset
- **Role-Based Access**: Secure route protection
- **Data Validation**: Input sanitization and validation
- **Firebase Security Rules**: Backend data protection

## 📦 Dependencies & Technology Stack

### 🔥 Firebase & Backend
```yaml
firebase_core: ^2.27.1          # Firebase initialization
firebase_auth: ^4.17.9          # Authentication services
cloud_firestore: ^4.15.9        # NoSQL database
firebase_storage: ^11.6.10      # File storage
```

### 🎯 State Management & Architecture
```yaml
provider: ^6.1.2                # State management
shared_preferences: ^2.2.2      # Local storage
```

### 🗺️ Location & Maps
```yaml
google_maps_flutter: ^2.12.2    # Interactive maps
geolocator: ^12.0.0             # GPS location services
geocoding: ^3.0.0               # Address resolution
```

### 🎨 UI & Design
```yaml
google_fonts: ^6.2.0           # Typography
flutter_svg: ^2.0.10+1         # SVG support
cupertino_icons: ^1.0.8        # iOS-style icons
```

### 📊 Data Visualization & Analytics
```yaml
fl_chart: ^0.66.2              # Charts and graphs
intl: ^0.19.0                  # Internationalization
```

### 🛠️ Utilities & Tools
```yaml
form_field_validator: ^1.1.0    # Form validation
email_validator: ^2.1.17        # Email validation
image_picker: ^1.0.7            # Image selection
path_provider: ^2.1.2           # File system paths
pdf: ^3.10.8                    # PDF generation
printing: ^5.12.0               # PDF printing
file_picker: ^6.1.1             # File selection
csv: ^5.1.1                     # CSV import/export
pin_code_fields: ^8.0.1         # PIN input fields
flutter_dotenv: ^5.2.1          # Environment variables
http: ^1.4.0                    # HTTP requests
```

### 🧪 Development & Testing
```yaml
flutter_test: sdk: flutter      # Testing framework
flutter_lints: ^5.0.0          # Code linting
```

## 🏗️ Project Structure & Architecture

### 📁 Detailed Project Structure
```
smart_kirana/
├── 📱 android/                 # Android-specific files
│   ├── app/
│   │   ├── google-services.json
│   │   └── build.gradle.kts
│   └── gradle/
├── 🍎 ios/                     # iOS-specific files
│   ├── Runner/
│   │   ├── GoogleService-Info.plist
│   │   └── Info.plist
│   └── Runner.xcodeproj/
├── 🌐 web/                     # Web-specific files
│   ├── index.html
│   ├── manifest.json
│   └── icons/
├── 📚 lib/                     # Main application code
│   ├── 🚀 main.dart           # Application entry point
│   ├── 🔧 firebase_options.dart # Firebase configuration
│   ├── 📊 models/             # Data models
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   ├── order_model.dart
│   │   ├── cart_item_model.dart
│   │   ├── category_model.dart
│   │   ├── payment_model.dart
│   │   ├── recommendation_model.dart
│   │   └── admin_dashboard_model.dart
│   ├── 🎯 providers/          # State management
│   │   ├── auth_provider.dart
│   │   ├── cart_provider.dart
│   │   ├── product_provider.dart
│   │   ├── order_provider.dart
│   │   ├── payment_provider.dart
│   │   ├── admin_provider.dart
│   │   ├── address_provider.dart
│   │   └── recommendation_provider.dart
│   ├── 🖥️ screens/            # UI screens
│   │   ├── auth/              # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   ├── email_verification_screen.dart
│   │   │   └── reset_password_confirm_screen.dart
│   │   ├── home/              # Customer screens
│   │   │   ├── home_screen.dart
│   │   │   ├── home_wrapper.dart
│   │   │   ├── cart_screen.dart
│   │   │   ├── product_detail_screen.dart
│   │   │   ├── category_products_screen.dart
│   │   │   ├── search_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── edit_profile_screen.dart
│   │   │   ├── address_screen.dart
│   │   │   └── about_us_screen.dart
│   │   ├── admin/             # Admin screens
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   ├── product_management_screen.dart
│   │   │   ├── category_management_screen.dart
│   │   │   ├── order_management_screen.dart
│   │   │   ├── user_management_screen.dart
│   │   │   ├── recommendation_management_screen.dart
│   │   │   ├── low_stock_screen.dart
│   │   │   ├── expiring_soon_screen.dart
│   │   │   └── product_import_screen.dart
│   │   ├── orders/            # Order management
│   │   │   ├── order_history_screen.dart
│   │   │   ├── order_detail_screen.dart
│   │   │   └── order_tracking_screen.dart
│   │   └── payment/           # Payment screens
│   │       ├── checkout_screen.dart
│   │       ├── payment_screen.dart
│   │       └── payment_success_screen.dart
│   ├── 🔧 services/           # Business logic
│   │   ├── auth_service.dart
│   │   ├── firebase_auth_service.dart
│   │   ├── location_service.dart
│   │   ├── maps_service.dart
│   │   ├── payment_service.dart
│   │   ├── order_service.dart
│   │   ├── recommendation_service.dart
│   │   ├── route_service.dart
│   │   └── admin_initialization_service.dart
│   ├── 🧩 widgets/            # Reusable components
│   │   ├── custom_button.dart
│   │   ├── custom_input_field.dart
│   │   ├── product_card.dart
│   │   ├── cart_summary_bar.dart
│   │   ├── product_filter_widget.dart
│   │   ├── order_tracking_map.dart
│   │   └── admin/
│   │       ├── admin_stats_card.dart
│   │       ├── admin_chart_widget.dart
│   │       └── admin_data_table.dart
│   └── 🛠️ utils/              # Utilities and constants
│       ├── constants.dart
│       ├── validators.dart
│       ├── csv_import_util.dart
│       └── geocoding_helper.dart
├── 🎨 assets/                 # Static assets
│   ├── images/
│   ├── icons/
│   └── sample_products.csv
├── 📄 .env                    # Environment variables
├── 🔥 firebase.json           # Firebase configuration
├── 📋 pubspec.yaml            # Dependencies
└── 📖 README.md               # Project documentation
```

## 🧪 Testing & Quality Assurance

### 🏃‍♂️ Running Tests
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run widget tests
flutter test test/widget_test.dart

# Generate test coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 🔍 Code Quality
```bash
# Analyze code quality
flutter analyze

# Format code
flutter format .

# Check for outdated dependencies
flutter pub outdated
```

## 🚀 Deployment & Production

### 📱 Mobile App Deployment
```bash
# Android Release Build
flutter build apk --release
flutter build appbundle --release

# iOS Release Build (macOS only)
flutter build ios --release
```

### 🌐 Web Deployment
```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### 🔧 Environment Configuration
- **Development**: Local Firebase emulators
- **Staging**: Firebase staging project
- **Production**: Firebase production project

## 🎯 AI & Machine Learning Features

### 🤖 Recommendation Engine
- **Collaborative Filtering**: User behavior analysis
- **Content-Based Filtering**: Product similarity matching
- **Hybrid Approach**: Combined recommendation strategies
- **Real-time Updates**: Dynamic recommendation updates

### 📊 Analytics & Insights
- **User Behavior Tracking**: Purchase patterns and preferences
- **Product Performance**: Sales analytics and trends
- **Business Intelligence**: Revenue and growth metrics
- **Predictive Analytics**: Demand forecasting

## 🔒 Security & Privacy

### 🛡️ Security Measures
- **Data Encryption**: End-to-end encryption for sensitive data
- **Secure Authentication**: Firebase Auth with email verification
- **API Security**: Rate limiting and request validation
- **Privacy Compliance**: GDPR and data protection standards

### 🔐 Firebase Security Rules
```javascript
// Example Firestore security rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Products are readable by all, writable by admins only
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'ADMIN';
    }
  }
}
```

## 🤝 Contributing & Development Guidelines

### 📋 Contribution Process
1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Follow coding standards** (Dart style guide)
4. **Write tests** for new features
5. **Update documentation** as needed
6. **Commit changes** (`git commit -m 'Add some AmazingFeature'`)
7. **Push to branch** (`git push origin feature/AmazingFeature`)
8. **Open a Pull Request**

### 🎨 Coding Standards
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent code formatting
- Write unit tests for business logic

### 🐛 Bug Reports & Feature Requests
- Use GitHub Issues for bug reports
- Provide detailed reproduction steps
- Include screenshots for UI issues
- Suggest improvements and new features

## 📄 License & Legal

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### 📜 Third-Party Licenses
- Flutter: BSD 3-Clause License
- Firebase: Google Terms of Service
- Google Maps: Google Maps Platform Terms
- Material Design: Apache License 2.0

## 🙏 Acknowledgments & Credits

### 🏆 Special Thanks
- **Firebase Team**: For comprehensive backend services
- **Google Maps Platform**: For location and mapping services
- **Flutter Team**: For the amazing cross-platform framework
- **Material Design**: For UI/UX guidelines and components
- **Open Source Community**: For various packages and libraries

### 👨‍💻 Development Team
- **Lead Developer**: Mohd Yusuf (mohdyusufr@gmail.com)
- **Project Type**: Academic/Portfolio Project
- **Institution**: [Your Institution Name]
- **Course**: [Course Name/Code]

## 📞 Support & Contact

### 🆘 Getting Help
- **Email**: mohdyusufr@gmail.com
- **GitHub Issues**: [Repository Issues Page]
- **Documentation**: This README file
- **Video Demos**: [Link to demo videos if available]

### 🌐 Project Links
- **Live Demo**: [Web App URL if deployed]
- **GitHub Repository**: [Repository URL]
- **Documentation**: [Additional docs if available]
- **API Documentation**: [API docs if available]

---

## 📝 Project Notes & Important Information

### ⚠️ Important Notes
- This project uses `web/index.html` for Google Maps API key configuration
- Environment variables are stored in `.env` file (not included in repository)
- Firebase configuration files are required for proper functionality
- Default admin credentials are for testing purposes only

### 🔄 Version History
- **v1.0.0**: Initial release with core features
- **v1.1.0**: Added AI recommendations and analytics
- **v1.2.0**: Enhanced UI/UX and performance optimizations
- **v1.3.0**: Added web platform support and responsive design

### 🎓 Educational Purpose
This project is developed for educational and portfolio purposes, demonstrating:
- Modern mobile app development with Flutter
- Cloud-based backend integration with Firebase
- AI-powered recommendation systems
- Cross-platform development best practices
- Real-world e-commerce application features

---

**© 2025 Smart Kirana Project. All rights reserved.**