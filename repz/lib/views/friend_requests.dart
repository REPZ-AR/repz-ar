import 'package:flutter/material.dart';
import '../model/friend.dart';
import '../services/friend_service.dart';

class FriendRequestsPage extends StatefulWidget {
  final bool isDarkMode;

  const FriendRequestsPage({super.key, required this.isDarkMode});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final _friendService = FriendService();

  List<Friend> _requests = [];
  bool _loading = true;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final requests = await _friendService.fetchPendingRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(Friend friend) async {
    setState(() => _processingIds.add(friend.id));
    try {
      await _friendService.acceptFriendRequest(requesterId: friend.id);
      if (mounted) {
        setState(() {
          _requests.removeWhere((f) => f.id == friend.id);
          _processingIds.remove(friend.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You and ${friend.name} are now friends!')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _processingIds.remove(friend.id));
    }
  }

  Future<void> _decline(Friend friend) async {
    setState(() => _processingIds.add(friend.id));
    try {
      await _friendService.declineFriendRequest(requesterId: friend.id);
      if (mounted) {
        setState(() {
          _requests.removeWhere((f) => f.id == friend.id);
          _processingIds.remove(friend.id);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _processingIds.remove(friend.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
    widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = widget.isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = primaryTextColor.withValues(alpha: 0.55);
    final accentColor =
    widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final avatarColors = const [
      Color(0xFFEEEDFE), Color(0xFFE1F5EE),
      Color(0xFFFAECE7), Color(0xFFFAEEDA), Color(0xFFFBEAF0),
    ];
    final avatarTextColors = const [
      Color(0xFF3C3489), Color(0xFF085041),
      Color(0xFF712B13), Color(0xFF633806), Color(0xFF72243E),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 48,
                color: secondaryTextColor),
            const SizedBox(height: 12),
            Text(
              'No pending requests',
              style: TextStyle(color: secondaryTextColor),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final friend = _requests[index];
          final colorIndex = index % avatarColors.length;
          final isProcessing = _processingIds.contains(friend.id);
          final hasPhoto = friend.avatarUrl != null &&
              friend.avatarUrl!.isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: avatarColors[colorIndex],
                foregroundImage: hasPhoto
                    ? NetworkImage(friend.avatarUrl!)
                    : null,
                child: hasPhoto
                    ? null
                    : Text(
                  friend.initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: avatarTextColors[colorIndex],
                  ),
                ),
              ),
              title: Text(
                friend.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Wants to be your friend',
                style: TextStyle(
                    fontSize: 12, color: secondaryTextColor),
              ),
              trailing: isProcessing
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decline
                  IconButton(
                    onPressed: () => _decline(friend),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.redAccent
                          .withValues(alpha: 0.1),
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accept
                  IconButton(
                    onPressed: () => _accept(friend),
                    icon: const Icon(Icons.check_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: accentColor
                          .withValues(alpha: 0.15),
                      foregroundColor: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}