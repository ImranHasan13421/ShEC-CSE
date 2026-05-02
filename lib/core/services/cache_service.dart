/// A simple in-memory cache service with TTL (time-to-live) based invalidation.
/// This reduces redundant Supabase fetches by skipping re-fetch if data is fresh.
library;

class CacheService {
  static final Map<String, DateTime> _timestamps = {};
  
  // Default cache TTL: 5 minutes
  static const Duration _defaultMaxAge = Duration(minutes: 5);

  /// Returns true if the cache for [key] is stale (older than [maxAge]) or doesn't exist.
  static bool isStale(String key, {Duration? maxAge}) {
    final ts = _timestamps[key];
    if (ts == null) return true;
    return DateTime.now().difference(ts) > (maxAge ?? _defaultMaxAge);
  }

  /// Marks [key] as freshly updated right now.
  static void markFresh(String key) {
    _timestamps[key] = DateTime.now();
  }

  /// Invalidates [key] so the next call to [isStale] returns true.
  static void invalidate(String key) {
    _timestamps.remove(key);
  }

  /// Invalidates all cache entries.
  static void invalidateAll() {
    _timestamps.clear();
  }
}

// Cache key constants
class CacheKeys {
  static const String gallery = 'gallery';
  static const String notices = 'notices';
  static const String contests = 'contests';
  static const String jobsRecommended = 'jobs_recommended';
  static const String jobsRecent = 'jobs_recent';
  static const String teachers = 'teachers';
  static const String members = 'members';
  static const String alumni = 'alumni';
  static const String exams = 'exams';
  static const String sessions = 'sessions';
}
