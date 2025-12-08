import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for search history entry
class SearchHistoryEntry {
  final int id;
  final String uid;
  final int buildingId;
  final DateTime createdAt;
  String? buildingName; // Optional, fetched separately

  SearchHistoryEntry({
    required this.id,
    required this.uid,
    required this.buildingId,
    required this.createdAt,
    this.buildingName,
  });

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      id: json['id'] as int,
      uid: json['uid']?.toString() ?? '',
      buildingId: json['building_id'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      buildingName: json['building_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'building_id': buildingId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Service for managing user search history in Supabase
class SearchHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get the last N search history entries for the current user
  ///
  /// Args:
  ///   limit: Number of entries to retrieve (default: 3)
  ///
  /// Returns:
  ///   List of SearchHistoryEntry ordered by most recent first
  Future<List<SearchHistoryEntry>> getLastSearches({int limit = 3}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_history')
          .select()
          .eq('uid', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((entry) => SearchHistoryEntry.fromJson(entry))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch search history: $e');
    }
  }

  /// Save a new search to user history
  ///
  /// Args:
  ///   buildingId: ID of the building that was searched
  ///
  /// Returns:
  ///   The created SearchHistoryEntry
  Future<SearchHistoryEntry> saveSearch(int buildingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_history')
          .insert({
            'uid': user.id,
            'building_id': buildingId,
          })
          .select()
          .single();

      return SearchHistoryEntry.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save search: $e');
    }
  }

  /// Get the most recent search entry for the current user
  ///
  /// Returns:
  ///   The last SearchHistoryEntry or null if no history exists
  Future<SearchHistoryEntry?> getLastSearch() async {
    try {
      final searches = await getLastSearches(limit: 1);
      return searches.isEmpty ? null : searches.first;
    } catch (e) {
      return null;
    }
  }

  /// Clear all search history for the current user
  Future<void> clearHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('user_history').delete().eq('uid', user.id);
    } catch (e) {
      throw Exception('Failed to clear history: $e');
    }
  }
}
