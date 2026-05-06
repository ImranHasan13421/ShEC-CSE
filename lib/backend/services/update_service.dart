import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService extends ChangeNotifier {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  static final SupabaseClient _client = Supabase.instance.client;

  // Local static build information
  static const int currentBuildNumber = 1;
  static const String currentVersion = '1.0.0';

  // State
  bool _isLoading = false;
  bool _hasUpdate = false;
  String _latestVersion = '';
  int _latestBuildNumber = 0;
  String _downloadUrl = '';
  String _releaseNotes = '';

  bool get isLoading => _isLoading;
  bool get hasUpdate => _hasUpdate;
  String get latestVersion => _latestVersion;
  int get latestBuildNumber => _latestBuildNumber;
  String get downloadUrl => _downloadUrl;
  String get releaseNotes => _releaseNotes;

  // Check for updates from Supabase
  Future<void> checkForUpdates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client
          .from('app_updates')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final int dbBuildNumber = response['build_number'] ?? 0;
        final String dbVersion = response['version'] ?? '';
        final String dbUrl = response['download_url'] ?? '';
        final String dbNotes = response['release_notes'] ?? '';

        if (dbBuildNumber > currentBuildNumber) {
          _hasUpdate = true;
          _latestVersion = dbVersion;
          _latestBuildNumber = dbBuildNumber;
          _downloadUrl = dbUrl;
          _releaseNotes = dbNotes;
        } else {
          _hasUpdate = false;
        }
      } else {
        _hasUpdate = false;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload a new app update (for Superusers)
  Future<void> uploadNewVersion({
    required String version,
    required int buildNumber,
    required String downloadUrl,
    required String releaseNotes,
  }) async {
    try {
      await _client.from('app_updates').insert({
        'version': version,
        'build_number': buildNumber,
        'download_url': downloadUrl,
        'release_notes': releaseNotes,
      });
      await checkForUpdates();
    } catch (e) {
      debugPrint('Error uploading version: $e');
      rethrow;
    }
  }

  // Trigger app download/install using url_launcher
  Future<void> triggerUpdate() async {
    if (_downloadUrl.isEmpty) return;
    final Uri uri = Uri.parse(_downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch update URL: $_downloadUrl');
    }
  }
}
