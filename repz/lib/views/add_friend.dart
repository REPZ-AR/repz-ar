import 'package:flutter/material.dart';
import '../model/friend.dart';
import '../services/friend_service.dart';

class AddFriendPage extends StatefulWidget {
  final bool isDarkMode;

  const AddFriendPage({super.key, required this.isDarkMode});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _friendService = FriendService();
  final _searchController = TextEditingController();

  List<Friend> _allUsers = [];
  List<Friend> _filtered = [];
  final Set<String> _sentIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _friendService.fetchAvailableUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _filtered = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _allUsers
          : _allUsers
          .where((u) => u.name.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _sendRequest(Friend user) async {
    setState(() => _sentIds.add(user.id));
    try {
      await _friendService.sendFriendRequest(receiverId: user.id);
    } catch (_) {
      if (mounted) setState(() => _sentIds.remove(user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send request. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
    widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final cardColor =
    widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = widget.isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = primaryTextColor.withValues(alpha: 0.55);
    final avatarColors = const [
      Color(0xFFEEEDFE), Color(0xFFE1F5EE),
      Color(0xFFFAECE7), Color(0xFFFAEEDA), Color(0xFFFBEAF0),
    ];
    final avatarTextColors = const [
      Color(0xFF3C3489), Color(0xFF085041),
      Color(0xFF712B13), Color(0xFF633806), Color(0xFF72243E),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'No users to add'
                    : 'No results for "${_searchController.text}"',
                style: TextStyle(color: secondaryTextColor),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = _filtered[index];
                final colorIndex =
                    index % avatarColors.length;
                final alreadySent = _sentIds.contains(user.id);
                final hasPhoto = user.avatarUrl != null &&
                    user.avatarUrl!.isNotEmpty;

                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                      avatarColors[colorIndex],
                      foregroundImage: hasPhoto
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: hasPhoto
                          ? null
                          : Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: avatarTextColors[
                          colorIndex],
                        ),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: alreadySent
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 16,
                            color: secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          'Sent',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    )
                        : FilledButton.tonal(
                      onPressed: () =>
                          _sendRequest(user),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor
                            .withValues(alpha: 0.15),
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 34),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}