import 'dart:io';
import 'package:calendar/pages/home_page.dart';
import 'package:calendar/pages/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:win32_registry/win32_registry.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await windowManager.ensureInitialized();

  // Configure window with custom title bar
  const mainWindowOptions = WindowOptions(
    size: Size(1200, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Changed to hidden for custom title bar
  );

  // Set up auto-start
  await configureAutoStart();

  // Initialize system tray first
  await initSystemTray();

  // Then initialize window
  await windowManager.waitUntilReadyToShow(mainWindowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  windowManager.addListener(MyWindowListener());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[200],
          elevation: 0,
        ),
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/reminders': (context) => const RemindersScreen(),
      },
      initialRoute: '/',
    );
  }
}

class MyWindowListener extends WindowListener {
  @override
  Future<void> onWindowClose() async {
    // Hide window but keep app running in tray
    await windowManager.hide();
  }
}

Future<void> configureAutoStart() async {
  if (!Platform.isWindows) return;

  final key = Registry.currentUser.createKey(
    r'Software\Microsoft\Windows\CurrentVersion\Run',
  );

  try {
    final exePath = Platform.resolvedExecutable;
    key.createValue(
      RegistryValue(
        'DayTrack', // the key name
        RegistryValueType.string,
        exePath,       // value: path to the executable
      ),
    );
  } finally {
    key.close();
  }
}

Future<void> initSystemTray() async {
  final systemTray = SystemTray();
  final menu = Menu();

  await systemTray.initSystemTray(
    iconPath: 'assets/app_icon.ico',
    toolTip: 'Calendar Reminders',
  );

  await menu.buildFrom([
    MenuItemLabel(
      label: 'Show Reminders',
      onClicked: (_) => showRemindersRoute(),
    ),
    MenuItemLabel(
      label: 'Open App',
      onClicked: (_) => windowManager.show(),
    ),
    MenuSeparator(),
    MenuItemLabel(
      label: 'Exit',
      onClicked: (_) => exit(0),
    ),
  ]);

  await systemTray.setContextMenu(menu);

  systemTray.registerSystemTrayEventHandler((eventName) {
    if (eventName == kSystemTrayEventClick) {
      showRemindersRoute();
    }
  });
}

Future<void> showRemindersRoute() async {
  // Show window if hidden
  if (!await windowManager.isVisible()) {
    await windowManager.show();
    await windowManager.focus();
  }

  // Navigate to reminders
  if (navigatorKey.currentState?.canPop() ?? false) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
  navigatorKey.currentState?.pushNamed('/reminders');
}