# Classroom - Google Classroom-like App

A Flutter application that mimics Google Classroom functionality, allowing teachers to create and manage classes with a modern, intuitive interface.

## Features

### 🎓 Class Management
- **Create Classes**: Teachers can create new classes with custom names, descriptions, subjects, and sections
- **Class Cards**: Beautiful grid layout displaying class information with color-coded themes
- **Class Details**: Detailed view showing class information, students, and class codes
- **Class Codes**: Unique codes for students to join classes

### 🎨 Modern UI/UX
- **Google Classroom-inspired Design**: Clean, modern interface similar to Google Classroom
- **Material Design 3**: Latest Material Design principles with custom theming
- **Responsive Layout**: Works on various screen sizes
- **Color Themes**: Customizable color schemes for each class

### 👥 User Management
- **Teacher Dashboard**: Centralized view of all created classes
- **Student Management**: View enrolled students in each class
- **User Roles**: Support for teachers and students

### 📱 Key Screens
1. **Home Screen**: Dashboard showing all classes in a grid layout
2. **Create Class Screen**: Form to create new classes with validation
3. **Class Detail Screen**: Detailed view of individual classes
4. **Class Cards**: Reusable components for displaying class information

## Getting Started

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android Emulator or Physical Device

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flow_score_v1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/
│   ├── class_model.dart      # Class data model
│   └── user_model.dart       # User data model
├── providers/
│   └── class_provider.dart   # State management
├── screens/
│   ├── home_screen.dart      # Main dashboard
│   ├── create_class_screen.dart  # Class creation form
│   └── class_detail_screen.dart  # Class details view
├── widgets/
│   └── class_card.dart       # Reusable class card component
├── services/                 # API and data services
└── utils/
    └── color_utils.dart      # Color utility functions
```

## Dependencies

- **provider**: State management
- **google_fonts**: Custom typography
- **flutter_svg**: SVG support
- **go_router**: Navigation
- **shared_preferences**: Local storage
- **http**: HTTP requests
- **image_picker**: Image selection
- **intl**: Internationalization

## Features in Detail

### Creating a Class
1. Tap the "Create Class" button on the home screen
2. Fill in the class details:
   - Class Name
   - Section
   - Subject
   - Room
   - Description
3. Choose a color theme for the class
4. Submit to create the class

### Class Management
- View all classes in a grid layout
- Tap on any class to see detailed information
- Access class codes for student enrollment
- Manage class settings and options

### Mock Data
The application includes sample data to demonstrate functionality:
- Sample teacher: John Doe
- Sample classes: Mathematics 101 and Physics Lab
- Sample students enrolled in classes

## Future Enhancements

- [ ] Student authentication and enrollment
- [ ] Assignment creation and management
- [ ] File upload and sharing
- [ ] Real-time notifications
- [ ] Grade management
- [ ] Calendar integration
- [ ] Discussion forums
- [ ] Mobile push notifications

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Screenshots

The application features a clean, modern interface with:
- Blue-themed header matching Google Classroom
- Card-based layout for classes
- Intuitive navigation
- Form validation
- Responsive design

## Support

For support and questions, please open an issue in the repository or contact the development team.
