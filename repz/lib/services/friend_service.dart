import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/friend.dart';

class FriendService {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  Friend _friendFromUserInfoRow(Map<String, dynamic> row) {
    final id = row['user_id'] as String;
    final fullName = (row['full_name'] as String?)?.trim();
    final name = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : 'User ${id.substring(0, 6)}';

    // First name only for display in bubbles
    final firstName = name.split(' ').first;

    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();

    return Friend(
      id: id,
      name: firstName,
      initials: initials,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  Future<List<Friend>> _fetchFriendDetails(List<String> friendIds) async {
    if (friendIds.isEmpty) return const [];

    final rows = await _supabase
        .from('users_info')
        .select('user_id, full_name, avatar_url')
        .inFilter('user_id', friendIds);

    final userInfoById = {
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        row['user_id'] as String: row,
    };

    return friendIds.map((id) {
      final userInfo = userInfoById[id];
      return _friendFromUserInfoRow(
        userInfo ?? <String, dynamic>{'user_id': id},
      );
    }).toList();
  }

  Future<List<Friend>> fetchFriends() async {
    final relations = await _supabase
        .from('friendships')
        .select('requester_id, receiver_id')
        .eq('status', 'accepted')
        .or('requester_id.eq.$_userId,receiver_id.eq.$_userId');

    if ((relations as List).isEmpty) return [];

    final friendIds = relations
        .cast<Map<String, dynamic>>()
        .map((row) => row['requester_id'] == _userId
        ? row['receiver_id'] as String
        : row['requester_id'] as String)
        .toList();

    return _fetchFriendDetails(friendIds);
  }

  Future<List<Friend>> fetchAvailableUsers() async {
    final existing = await _supabase
        .from('friendships')
        .select('requester_id, receiver_id')
        .or('requester_id.eq.$_userId,receiver_id.eq.$_userId');

    final existingIds = (existing as List)
        .cast<Map<String, dynamic>>()
        .expand((row) => [
      row['requester_id'] as String,
      row['receiver_id'] as String,
    ])
        .where((id) => id != _userId)
        .toSet();

    final result = await _supabase
        .from('users_info')
        .select('user_id, full_name, avatar_url')
        .neq('user_id', _userId);

    return (result as List)
        .cast<Map<String, dynamic>>()
        .where((row) => !existingIds.contains(row['user_id'] as String))
        .map((row) => _friendFromUserInfoRow(row))
        .toList();
  }

  Future<List<Friend>> fetchPendingRequests() async {
    final relations = await _supabase
        .from('friendships')
        .select('requester_id')
        .eq('receiver_id', _userId)
        .eq('status', 'pending');

    if ((relations as List).isEmpty) return [];

    final requesterIds = relations
        .cast<Map<String, dynamic>>()
        .map((row) => row['requester_id'] as String)
        .toList();

    return _fetchFriendDetails(requesterIds);
  }

  Future<void> sendFriendRequest({required String receiverId}) async {
    await _supabase.from('friendships').insert({
      'requester_id': _userId,
      'receiver_id': receiverId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest({required String requesterId}) async {
    await _supabase
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('requester_id', requesterId)
        .eq('receiver_id', _userId);
  }

  Future<void> declineFriendRequest({required String requesterId}) async {
    await _supabase
        .from('friendships')
        .update({'status': 'declined'})
        .eq('requester_id', requesterId)
        .eq('receiver_id', _userId);
  }

  Future<void> removeFriend({required String friendId}) async {
    await _supabase
        .from('friendships')
        .delete()
        .or(
      'and(requester_id.eq.$_userId,receiver_id.eq.$friendId),'
          'and(requester_id.eq.$friendId,receiver_id.eq.$_userId)',
    );
  }

  Future<int> fetchPendingRequestCount() async {
    final result = await _supabase
        .from('friendships')
        .select('id')
        .eq('receiver_id', _userId)
        .eq('status', 'pending');

    return (result as List).length;
  }
}