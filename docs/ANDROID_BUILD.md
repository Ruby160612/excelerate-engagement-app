# Android development build

## Verified on 23 October 2026

The debug APK build completed successfully with Flutter 3.47.7, JDK 21,
Gradle 8.14, AGP 8.11.1, and Kotlin 2.4.0. The APK signature verified, static
analysis reported no issues, and all 97 Flutter tests passed. The APK targets
Android API 36, supports API 24 and later, and includes ARM64 native libraries.
The successful build log is `/tmp/excelerate-android-final-build.log`.
Device installation was not tested because no Android phone was connected.

Use one Flutter SDK and a compatible build JDK consistently. This workstation
uses Flutter at `/opt/flutter` and OpenJDK 21 at
`/usr/lib/jvm/java-21-openjdk-amd64`.

## Workstation setup

```sh
/opt/flutter/bin/flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64
/opt/flutter/bin/flutter doctor -v
```

The JDK configuration is a Flutter user setting, so it also applies to other
Flutter projects using that configuration. On another workstation, substitute
its installed JDK 21 path.

Workspace settings in `.vscode/settings.json` select the same Flutter SDK and
Gradle import JDK, and set `JAVA_HOME` and `PATH` for new VS Code terminals.
Reload the VS Code window and open a new terminal after changing these settings.
The Java language server itself can use its bundled runtime; Gradle imports must
use the compatible build JDK.
Automatic Java-extension Gradle imports are disabled in this Flutter workspace
to prevent separate IDE imports of the Flutter/plugin Gradle projects competing
with the app build. Flutter's normal Android build commands still use Gradle.
For Java-specific Android IDE work, re-enable imports deliberately or open the
Android project separately with the same JDK selection.

Gradle 8.14 cannot run on Java 25. If the editor reports
`Unsupported class file major version 69`, check its Gradle JDK selection.
Keep the Gradle wrapper, Android Gradle Plugin, and Kotlin versions compatible;
Flutter's upcoming-support warnings are separate from a fatal build error.

## Build and run

Build an APK without needing a connected phone:

```sh
/opt/flutter/bin/flutter build apk --debug -v > /tmp/excelerate-android-debug-build.log 2>&1
```

Read progress from a second terminal:

```sh
tail -f /tmp/excelerate-android-debug-build.log
```

A successful debug build produces `build/app/outputs/flutter-apk/app-debug.apk`.
A cold build after a cleanup or SDK change may take longer than subsequent runs.
Use the log to distinguish ongoing compilation from a reported failure.

For the existing demo login and data flow on the connected TECNO phone:

```sh
/opt/flutter/bin/flutter devices
/opt/flutter/bin/flutter run -d 105015434T103530 --dart-define=USE_MOCK=true
```

Replace the device ID if it changes. If an error explicitly says Android SDK
licences have not been accepted, review them with
`/opt/flutter/bin/flutter doctor --android-licenses`.

## Interrupted builds and resource use

After a failed or interrupted build that reports invalid dependency files, clear
only generated outputs, then rebuild:

```sh
/opt/flutter/bin/flutter clean
/opt/flutter/bin/flutter pub get
/opt/flutter/bin/flutter build apk --debug
```

The project's Gradle settings cap the build at two workers, disable parallel
project execution, and cap Gradle and Kotlin daemon heaps to reduce contention
with the editor. Avoid starting multiple builds of this project at once.
Jetifier is disabled because the current plugins use AndroidX directly. This
avoids unnecessary rewriting of Flutter's large native-engine archives. Recheck
this setting if a future dependency still uses the old Android Support Library.

## Firebase scope

Firebase packages and platform configuration are present. An APK build verifies
that these native dependencies compile; it does not verify Firebase login,
Firestore permissions, shared opportunity publishing, or database persistence.
The current application still uses the HTTP API services or the mock backend.
Firebase initialization and service migration are separate application work.
