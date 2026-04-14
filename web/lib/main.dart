import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'platform/app_services.dart';
import 'services/music_service.dart';
import 'services/library_service.dart';
import 'providers/player_provider.dart';
import 'providers/library_provider.dart';
import 'providers/search_provider.dart';
import 'providers/cart_provider.dart';
import 'router/app_router.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.initialize();

  runApp(XiloApp(
    musicService: services.musicService,
    libraryService: services.libraryService,
  ));
}

class XiloApp extends StatelessWidget {
  final MusicService musicService;
  final LibraryService libraryService;

  const XiloApp({
    super.key,
    required this.musicService,
    required this.libraryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MusicService>.value(value: musicService),
        Provider<LibraryService>.value(value: libraryService),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(service: musicService),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(service: libraryService),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(service: musicService),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp.router(
        title: 'Xilo Play',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}