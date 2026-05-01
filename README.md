# shec_cse

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

## Build Instructions

### Important: Icon Tree Shaking
This project uses dynamic icons loaded from the database (via code points). Because of this, Flutter's default icon tree-shaking optimization will fail during release builds.

To build the APK successfully, you **must** use the `--no-tree-shake-icons` flag:

```bash
flutter build apk --no-tree-shake-icons
```
