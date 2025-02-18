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
bool isWindowClosed = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await windowManager.ensureInitialized();

  const mainWindowOptions = WindowOptions(
    size: Size(1200, 650),
    center: true,
    backgroundColor: Color(0x00000000),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await configureAutoStart();
  await initSystemTray();

  // Initialize window with all options at once
  await windowManager.waitUntilReadyToShow(mainWindowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Set prevent close after window is initialized
  await windowManager.setPreventClose(true);

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
    isWindowClosed = true;
    await windowManager.hide();
  }

  @override
  void onWindowEvent(String eventName) {
    // Handle window focus event to restore window
    if (eventName == 'focus') {
      if (isWindowClosed) {
        showMainWindow();
      }
    }
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
        'DayTrack',
        RegistryValueType.string,
        exePath,
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
      onClicked: (_) async {
        await showRemindersRoute();
      },
    ),
    MenuItemLabel(
      label: 'Open App',
      onClicked: (_) async {
        await showMainWindow();
      },
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
      systemTray.popUpContextMenu();
    } else if (eventName == kSystemTrayEventRightClick) {
      systemTray.popUpContextMenu();
    }
  });
}

Future<void> showMainWindow() async {
  isWindowClosed = false;
  final isVisible = await windowManager.isVisible();
  if (!isVisible) {
    await windowManager.show();
    await windowManager.focus();
  }
  navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
}

Future<void> showRemindersRoute() async {
  isWindowClosed = false;
  if (!await windowManager.isVisible()) {
    await windowManager.show();
    await windowManager.focus();
  }

  if (navigatorKey.currentState?.canPop() ?? false) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
  navigatorKey.currentState?.pushNamed('/reminders');
}