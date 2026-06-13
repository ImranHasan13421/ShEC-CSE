import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ShEC_CSE/backend/services/notification_service.dart';

class UpdateService extends ChangeNotifier {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  static final SupabaseClient _client = Supabase.instance.client;

  // Local static build information
  static const int currentBuildNumber = 33;
  static const String currentVersion = '0.9.2';

  // State
  bool _isLoading = false;
  bool _hasUpdate = false;
  bool _isMajor = false;
  String _latestVersion = '';
  int _latestBuildNumber = 0;
  String _downloadUrl = '';
  String _releaseNotes = '';

  bool get isLoading => _isLoading;
  bool get hasUpdate => _hasUpdate;
  bool get isMajor => _isMajor;
  String get latestVersion => _latestVersion;
  int get latestBuildNumber => _latestBuildNumber;
  String get downloadUrl => _downloadUrl;
  String get releaseNotes => _releaseNotes;

  // Compares two semver strings (e.g. "1.2.3" vs "0.9.1").
  // Returns true if [remote] is strictly newer than [local].
  bool _isNewerVersion(String local, String remote) {
    try {
      final localParts = local.split('.').map(int.parse).toList();
      final remoteParts = remote.split('.').map(int.parse).toList();

      // Pad shorter list with zeros so lengths match
      while (localParts.length < 3) { localParts.add(0); }
      while (remoteParts.length < 3) { remoteParts.add(0); }

      for (int i = 0; i < 3; i++) {
        if (remoteParts[i] > localParts[i]) return true;
        if (remoteParts[i] < localParts[i]) return false;
      }
      return false; // versions are identical
    } catch (_) {
      // If parsing fails fall back to build number comparison
      return false;
    }
  }

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
        final bool dbIsMajor = response['is_major'] ?? false;

        // Primary check: semantic version string comparison (e.g. "1.0.0" > "0.9.1")
        // Tiebreaker: if version strings are equal, fall back to build number
        final bool versionNewer = _isNewerVersion(currentVersion, dbVersion);
        final bool sameVersion = dbVersion == currentVersion;
        final bool buildNewer = sameVersion && dbBuildNumber > currentBuildNumber;

        if (versionNewer || buildNewer) {
          _hasUpdate = true;
          _latestVersion = dbVersion;
          _latestBuildNumber = dbBuildNumber;
          _downloadUrl = dbUrl;
          _releaseNotes = dbNotes;
          _isMajor = dbIsMajor;
          debugPrint(
            'Update available: $currentVersion (build $currentBuildNumber) '
            '→ $dbVersion (build $dbBuildNumber)',
          );
        } else {
          _hasUpdate = false;
          _isMajor = false;
          debugPrint(
            'App is up to date: $currentVersion (build $currentBuildNumber)',
          );
        }
      } else {
        _hasUpdate = false;
        _isMajor = false;
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
    bool isMajor = false,
  }) async {
    try {
      await _client.from('app_updates').insert({
        'version': version,
        'build_number': buildNumber,
        'download_url': downloadUrl,
        'release_notes': releaseNotes,
        'is_major': isMajor,
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

  // Update History State
  List<Map<String, dynamic>> _updateHistory = [];
  List<Map<String, dynamic>> get updateHistory => _updateHistory;
  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;

  Future<void> fetchUpdateHistory() async {
    _isHistoryLoading = true;
    notifyListeners();
    try {
      final data = await _client
          .from('app_updates')
          .select()
          .order('created_at', ascending: false);
      _updateHistory = List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Error fetching update history: $e');
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  // Real-time Postgres subscriptions for app updates
  RealtimeChannel? _updateChannel;

  void subscribeToUpdates() {
    if (_updateChannel != null) {
      debugPrint('Already subscribed to updates channel, skipping duplicate subscription.');
      return;
    }

    _updateChannel = _client
      .channel('public:app_updates')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'app_updates',
        callback: (payload) async {
          debugPrint('Real-time app update received in background database listener: ${payload.newRecord}');
          await checkForUpdates();
          
          if (_hasUpdate) {
            NotificationService.showNotification(
              id: 99,
              title: _isMajor ? '🚨 Critical App Update!' : '🚀 New App Update Available',
              body: 'Version $_latestVersion (Build $_latestBuildNumber) is now available. Click to download.',
            );
          }
        },
      );
    
    _updateChannel!.subscribe();
  }

  Future<void> unsubscribeFromUpdates() async {
    if (_updateChannel != null) {
      debugPrint('Unsubscribing from updates channel...');
      try {
        await _client.removeChannel(_updateChannel!);
      } catch (e) {
        debugPrint('Error removing updates channel: $e');
      }
      _updateChannel = null;
    }
  }
}
