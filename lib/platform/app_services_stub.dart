import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/music_repository.dart';
import '../repositories/library_repository.dart';
import '../services/music_service.dart';
import '../services/library_service.dart';

const _supabaseUrl = 'https://bvnhzwpmcjepaebgymtn.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2bmh6d3BtY2plcGFlYmd5bXRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4NTAyMjAsImV4cCI6MjA5MTQyNjIyMH0.bvskj-qh-8RLWj_uSKkNE4R8rQqyzQ09F2pQQhdzR_s';

/// Web version — initializes Supabase for auth (magic links) but uses mock
/// data for the music catalog. The creator upload service reads from
/// Supabase.instance.client directly when authenticated.
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
    } catch (_) {
      // Already initialized or failed — continue with mock data.
    }
    return AppServices._(
      musicService: MusicService(repository: MusicRepository()),
      libraryService: LibraryService(repository: LibraryRepository()),
    );
  }
}
