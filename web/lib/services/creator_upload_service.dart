import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Web-only service that handles real file uploads to Supabase Storage
/// and database inserts for the creator dashboard.
/// Never imported on mobile — only used from web_home_screen.dart which
/// is itself gated behind kIsWeb routes.
class CreatorUploadService {
  final SupabaseClient _client;

  CreatorUploadService(this._client);

  // ── Auth helpers ────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> sendMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'https://xilo-music.com/web/creator',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── File picker helpers ─────────────────────────────────────────────────────

  /// Opens a native file picker and returns the selected file, or null if cancelled.
  Future<html.File?> pickFile({required List<String> acceptedTypes}) async {
    final completer = Completer<html.File?>();
    final input = html.FileUploadInputElement()
      ..accept = acceptedTypes.join(',')
      ..multiple = false;
    input.onChange.listen((_) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        completer.complete(files[0]);
      } else {
        completer.complete(null);
      }
    });
    input.click();
    return completer.future;
  }

  /// Opens a file picker for multiple audio files.
  Future<List<html.File>> pickMultipleAudioFiles() async {
    final completer = Completer<List<html.File>>();
    final input = html.FileUploadInputElement()
      ..accept = '.mp3,.wav,.flac,.aiff,.aif'
      ..multiple = true;
    input.onChange.listen((_) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        completer.complete(List<html.File>.from(files));
      } else {
        completer.complete([]);
      }
    });
    input.click();
    return completer.future;
  }

  /// Reads a File as Uint8List bytes.
  Future<Uint8List> readFileBytes(html.File file) async {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      final result = reader.result;
      completer.complete(result as Uint8List);
    });
    reader.onError.listen((_) => completer.completeError('File read error'));
    return completer.future;
  }

  // ── Upload helpers ──────────────────────────────────────────────────────────

  /// Uploads artwork bytes to the artwork Supabase Storage bucket.
  /// Returns the public URL of the uploaded file.
  Future<String> uploadArtwork({
    required html.File file,
    required String releaseTitle,
  }) async {
    final userId = currentUser?.id ?? 'unknown';
    final ext = file.name.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'creators/$userId/${timestamp}_artwork.$ext';

    final bytes = await readFileBytes(file);

    await _client.storage.from('artwork').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: false,
          ),
        );

    final publicUrl = _client.storage.from('artwork').getPublicUrl(path);
    return publicUrl;
  }

  /// Uploads a single audio file to the audio Supabase Storage bucket.
  /// Returns the public URL.
  Future<String> uploadAudio({
    required html.File file,
    required String releaseTitle,
    int trackNumber = 1,
  }) async {
    final userId = currentUser?.id ?? 'unknown';
    final ext = file.name.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = releaseTitle
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .toLowerCase();
    final path =
        'creators/$userId/${timestamp}_track${trackNumber}_$safeName.$ext';

    final bytes = await readFileBytes(file);

    await _client.storage.from('audio').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'audio/$ext',
            upsert: false,
          ),
        );

    return _client.storage.from('audio').getPublicUrl(path);
  }

  // ── Database writes ─────────────────────────────────────────────────────────

  /// Ensures an artist row exists for the current creator.
  /// If the creator already has an artist profile, returns its ID.
  /// Otherwise, creates one and returns the new ID.
  Future<String> ensureArtistProfile({
    required String artistName,
    required String imageUrl,
    required bool isAiCreator,
  }) async {
    final userId = currentUser!.id;

    // Check if creator already has an artist row
    final existing = await _client
        .from('artists')
        .select('id')
        .eq('creator_user_id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'].toString();
    }

    // Create a new artist row
    final result = await _client
        .from('artists')
        .insert({
          'name': artistName,
          'image_url': imageUrl,
          'is_ai_creator': isAiCreator,
          'creator_user_id': userId,
          'bio': '',
          'follower_count': 0,
          'play_count': 0,
          'upload_count': 0,
          'genres': <String>[],
        })
        .select('id')
        .single();

    return result['id'].toString();
  }

  /// Inserts an album row and returns its ID.
  Future<String> insertAlbum({
    required String title,
    required String artistId,
    required String artistName,
    required String artUrl,
    required String type,
    required String genre,
    required String mood,
    required String credits,
    required bool isExplicit,
    required bool isAiCreated,
    required bool availableForPurchase,
    required bool availableForLicensing,
    required bool allowPersonalLicense,
    required bool allowCommercialLicense,
    required bool allowSyncLicense,
  }) async {
    final result = await _client
        .from('albums')
        .insert({
          'title': title,
          'artist_id': artistId,
          'artist_name': artistName,
          'art_url': artUrl,
          'type': type.toLowerCase(),
          'genre': genre,
          'mood': mood,
          'credits': credits,
          'is_explicit': isExplicit,
          'is_ai_created': isAiCreated,
          'release_year': DateTime.now().year,
          'is_available_for_purchase': availableForPurchase,
          'is_available_for_licensing': availableForLicensing,
          'allow_personal_license': allowPersonalLicense,
          'allow_commercial_license': allowCommercialLicense,
          'allow_sync_license': allowSyncLicense,
          'track_ids': <String>[],
          'creator_user_id': currentUser!.id,
          'price': 9.99,
        })
        .select('id')
        .single();

    return result['id'].toString();
  }

  /// Inserts a single track row and returns its ID.
  Future<String> insertTrack({
    required String title,
    required String artistId,
    required String artistName,
    required String albumId,
    required String albumTitle,
    required String artUrl,
    required String audioUrl,
    required String genre,
    required String mood,
    required String credits,
    required String lyrics,
    required bool isExplicit,
    required bool isAiCreated,
    required bool availableForPurchase,
    required bool availableForLicensing,
    required int trackNumber,
    required int durationMs,
    required int previewStartMs,
  }) async {
    final result = await _client
        .from('tracks')
        .insert({
          'title': title,
          'artist_id': artistId,
          'artist_name': artistName,
          'album_id': albumId,
          'album_title': albumTitle,
          'art_url': artUrl,
          'audio_url': audioUrl,
          'genre': genre,
          'mood': mood,
          'credits': credits,
          'lyrics': lyrics,
          'is_explicit': isExplicit,
          'is_ai_created': isAiCreated,
          'release_year': DateTime.now().year,
          'is_available_for_purchase': availableForPurchase,
          'is_available_for_licensing': availableForLicensing,
          'duration_ms': durationMs,
          'preview_start_ms': previewStartMs,
          'track_number': trackNumber,
          'play_count': 0,
          'creator_user_id': currentUser!.id,
          'price': 1.29,
        })
        .select('id')
        .single();

    return result['id'].toString();
  }

  /// Updates the album's track_ids array after all tracks are inserted.
  Future<void> updateAlbumTrackIds({
    required String albumId,
    required List<String> trackIds,
  }) async {
    await _client.from('albums').update({'track_ids': trackIds}).eq(
        'id', albumId);
  }

  /// Updates the artist's upload_count after a successful upload.
  Future<void> incrementUploadCount(String artistId, int count) async {
    await _client.rpc('increment_upload_count', params: {
      'artist_id': artistId,
      'increment_by': count,
    });
  }

  // ── Creator's own tracks ────────────────────────────────────────────────────

  /// Fetches all tracks uploaded by the current creator, newest first.
  Future<List<Map<String, dynamic>>> fetchMyTracks() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final result = await _client
        .from('tracks')
        .select()
        .eq('creator_user_id', userId)
        .order('created_at', ascending: false);

    return (result as List).cast<Map<String, dynamic>>();
  }

  /// Deletes a track and its associated audio file from Storage.
  Future<void> deleteTrack({
    required String trackId,
    required String audioUrl,
  }) async {
    // Extract the storage path from the public URL
    final uri = Uri.parse(audioUrl);
    final pathSegments = uri.pathSegments;
    // Path after /storage/v1/object/public/audio/
    final storagePathIndex = pathSegments.indexOf('audio');
    if (storagePathIndex >= 0 &&
        storagePathIndex < pathSegments.length - 1) {
      final storagePath =
          pathSegments.sublist(storagePathIndex + 1).join('/');
      try {
        await _client.storage.from('audio').remove([storagePath]);
      } catch (_) {
        // File may already be gone — continue with DB delete
      }
    }

    await _client.from('tracks').delete().eq('id', trackId);
  }
}
