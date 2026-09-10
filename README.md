# digital_board

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)





For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Because you changed the folder name or opened a new session, PowerShell spawned a fresh shell that does not have `C:\Users\Uni\flutter\bin` in its active environment path.

Here is the quick fix to inject it into your active terminal and permanently into PowerShell:

1. **Temporarily append Flutter to active PowerShell session:** Immediate fix for current terminal.
Paste this command directly into your terminal in VS Code and press Enter:

```powershell
$env:Path += ";C:\Users\Uni\flutter\bin"

```

*Verification:* Run `flutter --version`. It should immediately print the Flutter version information without errors.


2. **Permanently set Path for your Windows User:** Prevents this from happening again.
To ensure every new PowerShell terminal automatically finds `flutter`, run this one-liner in your terminal:

```powershell
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Users\Uni\flutter\bin", "User")

```

*Verification:* Opening any new terminal tab in VS Code in the future will automatically recognize `flutter`.


3. **Run the project init and dependency commands:** Resume setup.
Now run your project generation and package commands:

```powershell
flutter create . --project-name=digital_board --platforms=android,web
flutter pub add flutter_colorpicker provider

```

*Verification:* The terminal should show `All done!` followed by `Changed 2 dependencies!`.

