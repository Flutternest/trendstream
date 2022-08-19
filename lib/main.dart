import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app/features/movies/views/movies_dashboard/movies_dashboard.dart';
import 'router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Pass all uncaught errors from the framework to Crashlytics.
  // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Latest Movies',
        theme: ThemeData.dark().copyWith(
            platform: TargetPlatform.macOS,
            appBarTheme: Theme.of(context)
                .appBarTheme
                .copyWith(color: Colors.grey[900])),
        // home: true
        //     ? const PlayerView()
        //     : Consumer(
        home: const HomeView(),
        // home: Consumer(
        //   builder: (context, ref, child) => AuthWidget(
        //     nonSignedInBuilder: (_) => const LoginView(),
        //     signedInBuilder: (_) {
        //       return const HomeView();
        //     },
        //   ),
        // ),
        onGenerateRoute: AppRouter.onGenerateRoute,
        navigatorKey: AppRouter.navigatorKey,
      ),
    );
  }
}
