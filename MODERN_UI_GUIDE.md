# UI Modernization - Quick Reference Guide

## 🎨 Modern Design Components

### 1. Glassmorphic Container
Use this pattern for all modern card containers:

```dart
Container(
  margin: const EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: AppTheme.purpleGradient,
    boxShadow: [
      BoxShadow(
        color: AppTheme.primaryPurple.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: // Your content here
      ),
    ),
  ),
)
```

### 2. Glassmorphic Dialog
Replace AlertDialog with this pattern:

```dart
Dialog(
  backgroundColor: Colors.transparent,
  insetPadding: const EdgeInsets.all(16),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.purpleGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: // Dialog content
      ),
    ),
  ),
)
```

### 3. Glassmorphic TextField
Use the custom component:

```dart
GlassmorphicTextField(
  label: 'Field Label',
  hint: 'Hint text',
  controller: controller,
  keyboardType: TextInputType.text,
  obscureText: false,
  maxLines: 1,
)
```

### 4. Modern AppBar
Use consistent styling across screens:

```dart
AppBar(
  title: const Text('Screen Title'),
  backgroundColor: AppTheme.primaryPurple,
  elevation: 0,
)
```

### 5. Color-Coded Buttons
Follow this color convention:

```dart
// Success/Add Action
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.successGreen,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: () { },
  child: const Text('Add'),
),

// Cancel/Secondary Action
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white.withOpacity(0.2),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: () { },
  child: const Text('Cancel'),
),

// Delete/Danger Action
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.errorRed,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: () { },
  child: const Text('Delete'),
)
```

### 6. Real-Time List Items
Pattern for displaying Firestore data:

```dart
StreamBuilder<List<MyModel>>(
  stream: myService.streamItems(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final items = snapshot.data ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items available',
          style: TextStyle(color: AppTheme.textLight),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        return // Glassmorphic container with item
      },
    );
  },
)
```

## 🎯 Real-Time Data Integration

### Firestore Collection Queries
Get live counts:

```dart
final volunteerSnap = await FirebaseFirestore.instance
  .collection('volunteers').count().get();
print(volunteerSnap.count); // Returns integer count

// Alternative: Stream updates
FirebaseFirestore.instance
  .collection('volunteers')
  .snapshots()
  .listen((snapshot) {
    print('Total: ${snapshot.docs.length}');
  });
```

### Stream-Based Updates
For real-time list updates:

```dart
Stream<List<VolunteerModel>> streamVolunteers() {
  return FirebaseFirestore.instance
    .collection('volunteers')
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => VolunteerModel.fromJson(doc.data()))
      .toList());
}
```

### Error Handling with Theme
Modern error messages:

```dart
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Error message'),
      backgroundColor: AppTheme.errorRed,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

## 📱 Responsive Design

### Layout Spacing
- Small gaps: `const SizedBox(height: 8)`
- Medium gaps: `const SizedBox(height: 12)`
- Large gaps: `const SizedBox(height: 16)` or `const SizedBox(height: 24)`

### Padding Consistency
- Container padding: `const EdgeInsets.all(12)` or `const EdgeInsets.all(16)`
- Dialog padding: `const EdgeInsets.all(24)`
- List item margin: `const EdgeInsets.symmetric(vertical: 8)`

### Border Radius
- Cards/Containers: `BorderRadius.circular(16)`
- Buttons: `BorderRadius.circular(12)`
- Dialogs: `BorderRadius.circular(20)`

## 🎨 Color Usage Guidelines

| Use Case | Color | Example |
|----------|-------|---------|
| Primary Action | `AppTheme.successGreen` | Add, Save, Submit buttons |
| Danger Action | `AppTheme.errorRed` | Delete, Cancel, Error states |
| Warning Action | `AppTheme.warningOrange` | Decrease quantity, warnings |
| Background | `AppTheme.surfaceLight` | Scaffold backgroundColor |
| Text Primary | `AppTheme.textDark` | Main text and titles |
| Text Secondary | `AppTheme.textLight` | Helper text and labels |
| Gradient | `AppTheme.purpleGradient` | Backgrounds and containers |

## 🔄 Common Patterns

### Modal Dialog with Form
```dart
showDialog(
  context: context,
  builder: (ctx) => Dialog(
    backgroundColor: Colors.transparent,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.purpleGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dialog Title',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Form fields here
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Action buttons
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
```

### List Item with Actions
```dart
Container(
  margin: const EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: AppTheme.purpleGradient,
    boxShadow: [
      BoxShadow(
        color: AppTheme.primaryPurple.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.successGreen.withOpacity(0.3),
            child: const Icon(Icons.person, color: AppTheme.successGreen),
          ),
          title: Text('Item Title', style: const TextStyle(color: Colors.white)),
          subtitle: Text('Subtitle', style: TextStyle(color: Colors.white.withOpacity(0.8))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () { }),
              IconButton(icon: const Icon(Icons.delete, color: AppTheme.errorRed), onPressed: () { }),
            ],
          ),
        ),
      ),
    ),
  ),
)
```

## 📋 Checklist for New Screens

When modernizing a new screen, ensure:

- [ ] Replace `AlertDialog` with modern `Dialog` + `BackdropFilter`
- [ ] Replace `TextField` with `GlassmorphicTextField`
- [ ] Replace `Card` with glassmorphic `Container`
- [ ] Update `AppBar` with `AppTheme.primaryPurple` background
- [ ] Set `Scaffold` background to `AppTheme.surfaceLight`
- [ ] Use `AppTheme` colors for all action buttons
- [ ] Implement `StreamBuilder` for Firestore data
- [ ] Add proper error handling with themed `SnackBar`
- [ ] Test with real Firestore data
- [ ] Verify no compilation errors with `flutter analyze`

## 🚀 Testing Command

```bash
# Run analysis to check for issues
flutter analyze

# Get dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Android emulator
flutter run -d emulator-5554
```

---
*This guide ensures consistency across the Disaster Link application.*
