# MaalGadi - Inventory Management App

## Overview
MaalGadi is a comprehensive inventory management mobile application built with Flutter and Firebase, designed specifically for small businesses to manage their store inventory efficiently.

## Features Implemented

### 1. Authentication System
- **Firebase Authentication** with email and password
- User registration and login functionality
- Secure authentication state management
- Automatic login persistence

### 2. Dashboard (Home Screen)
- **Real-time Statistics Display**:
  - Total products count
  - Low stock alerts with threshold-based warnings
  - Daily stock movement summary (incoming/outgoing)
- **Quick Actions**:
  - Add new product button
  - Navigation to different sections

### 3. Product Management
- **Add Product Screen**:
  - Product name, category, quantity, cost price, sell price
  - Low stock threshold configuration
  - Category management (existing categories dropdown + new category option)
  - Form validation and error handling

- **Product Listing**:
  - Search functionality (by name and category)
  - Category-based filtering
  - Low stock filter toggle
  - Real-time updates from Firebase

- **Product Details**:
  - Comprehensive product information display
  - Stock update functionality with reason tracking
  - Edit and delete options
  - Profit calculation display

### 4. Stock History Tracking
- **Movement Tracking**:
  - Automatic tracking of all stock changes
  - Inward and outward movement categorization
  - Reason logging for each movement
  - User attribution for changes

- **History Screen**:
  - Chronological list of all stock movements
  - Search and filter capabilities
  - Date-wise filtering
  - Movement type filtering (Stock In/Stock Out)

### 5. Additional Features
- **CSV Export**: Export product inventory to CSV format
- **Modern UI**: Clean, flat design with green and white color palette
- **Responsive Design**: Optimized for mobile devices
- **Bottom Navigation**: Easy access to all main sections
- **Real-time Updates**: Firebase Firestore integration for live data

## Technical Architecture

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget with setState
- **UI Components**: Material Design 3
- **Navigation**: Bottom navigation with multiple screens

### Backend
- **Database**: Firebase Firestore (NoSQL)
- **Authentication**: Firebase Auth
- **Real-time Updates**: Firestore streams
- **Data Structure**:
  - Products collection
  - Stock movements collection
  - User-based data isolation

### Firebase Configuration
- Project ID: maalghadi-404b3
- Authentication domain: maalghadi-404b3.firebaseapp.com
- Database URL: https://maalghadi-404b3-default-rtdb.firebaseio.com
- Storage bucket: maalghadi-404b3.appspot.com

## App Structure

```
lib/
├── main.dart                 # App entry point and theme configuration
├── firebase_options.dart     # Firebase configuration
├── models/
│   ├── product.dart         # Product data model
│   └── stock_movement.dart  # Stock movement data model
├── services/
│   └── product_service.dart # Firebase operations and business logic
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   ├── home_screen.dart      # Bottom navigation container
    │   └── dashboard_screen.dart # Main dashboard with statistics
    ├── products/
    │   ├── products_screen.dart      # Product listing and management
    │   ├── add_product_screen.dart   # Add/edit product form
    │   └── product_detail_screen.dart # Product details and actions
    ├── stock/
    │   └── stock_history_screen.dart # Stock movement history
    └── profile/
        └── profile_screen.dart       # User profile and logout
```

## Key Features Highlights

1. **Real-time Inventory Tracking**: All changes are immediately reflected across the app
2. **Low Stock Alerts**: Automatic warnings when products fall below threshold
3. **Comprehensive Search**: Find products by name, category, or stock status
4. **Movement History**: Complete audit trail of all inventory changes
5. **User-friendly Interface**: Intuitive design following Material Design principles
6. **Data Export**: CSV export functionality for external reporting
7. **Secure Authentication**: Firebase-based user management

## Business Benefits

- **Inventory Control**: Real-time tracking prevents stockouts and overstocking
- **Cost Management**: Track cost and selling prices for profit analysis
- **Audit Trail**: Complete history of all inventory movements
- **Efficiency**: Quick search and filter capabilities save time
- **Scalability**: Cloud-based solution grows with business needs
- **Accessibility**: Mobile-first design for on-the-go management

## Future Enhancement Possibilities

1. **Role-based Access Control**: Admin and staff user roles
2. **Barcode Scanning**: Quick product identification and updates
3. **Supplier Management**: Track suppliers and purchase orders
4. **Sales Integration**: Connect with POS systems
5. **Analytics Dashboard**: Advanced reporting and insights
6. **Multi-location Support**: Manage inventory across multiple stores
7. **Automated Reordering**: Set up automatic purchase suggestions

## Installation and Setup

1. Ensure Flutter is installed and configured
2. Clone the project repository
3. Run `flutter pub get` to install dependencies
4. Configure Firebase project with provided credentials
5. Run `flutter run` to launch the app

The app is designed to be production-ready with proper error handling, user feedback, and a professional user interface suitable for small business inventory management needs.

