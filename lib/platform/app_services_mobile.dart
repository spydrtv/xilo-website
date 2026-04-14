import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/music_repository.dart';
import '../repositories/library_repository.dart';
import '../repositories/supabase_music_repository.dart';
import '../repositories/supabase_library_repository.dart';
import '../services/music_service.dart';
import '../services/library_service.dart';

const _supabaseUrl = 'https://bvnhzwpmcjepaebgymtn.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2bmh6d3BtY2plcGFlYmd5bXRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4NTAyMjAsImV4cCI6MjA5MTQyNjIyMH0.bvskj-qh-8RLWj_uSKkNE4R8rQqyzQ09F2pQQhdzR_s';

/// Mobile implementation — initializes Supabase and wires real repositories.
/// Falls back silently to mock data if Supabase is unreachable.
class AppServices {
  final MusicService musicService;
  final LibraryService libraryService;

  AppServices._({
    required this.musicService,
    required this.libraryService,
  });

  static Future<AppServices> initialize() async {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );

      final client = Supabase.instance.client;
      final musicRepo = SupabaseMusicRepository(client: client);
      final libraryRepo = SupabaseLibraryRepository(client: client);

      // Pre-load catalog data so all sync getters work instantly after launch.
      await musicRepo.preload();

      return AppServices._(
        musicService: MusicService(repository: musicRepo),
        libraryService: LibraryService(repository: libraryRepo),
      );
    } catch (_) {
      // Supabase unreachable — fall back to mock data silently.
      return AppServices._(
        musicService: MusicService(repository: MusicRepository()),
        libraryService: LibraryService(repository: LibraryRepository()),
      );
    }
  }
}
