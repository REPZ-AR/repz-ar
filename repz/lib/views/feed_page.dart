import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/feed_item.dart';

class FeedPage extends StatefulWidget {
  final bool isDarkMode;

  const FeedPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<FeedItem>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _feedFuture = _fetchFeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Supabase fetch ──────────────────────────────────────────

  Future<List<FeedItem>> _fetchFeed() async {
    final response = await Supabase.instance.client
        .from('feed_items')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _refresh() {
    setState(() {
      _feedFuture = _fetchFeed();
    });
  }

  // ── Theme helpers ───────────────────────────────────────────

  Color get _accent =>
      widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
  Color get _bg =>
      widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
  Color get _card =>
      widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _text => widget.isDarkMode ? Colors.white : Colors.black;
  Color? get _subText =>
      widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'Feed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _text,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: _text),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: _subText,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: FutureBuilder<List<FeedItem>>(
        future: _feedFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: _subText, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load feed',
                    style: TextStyle(color: _text, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refresh,
                    child: Text('Retry', style: TextStyle(color: _accent)),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          // Split tabs: Following = only 'activity' type; For You = everything
          final forYouItems = items;
          final followingItems =
          items.where((i) => i.type == 'activity').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFeedList(forYouItems),
              _buildFeedList(followingItems),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Feed list
  // ─────────────────────────────────────────────────────────────

  Widget _buildFeedList(List<FeedItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nothing here yet 👀',
          style: TextStyle(color: _subText, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _dispatchItem(items[i]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Template dispatcher  ← the key piece
  // ─────────────────────────────────────────────────────────────

  Widget _dispatchItem(FeedItem item) {
    final p = item.payload;

    switch (item.type) {
    // ── streak ──────────────────────────────────────────────
      case 'streak':
        return _buildStreakCard(
          name: p['name'] as String,
          avatars: List<String>.from(p['avatars'] as List),
          achievement: p['achievement'] as String,
          days: p['days'] as int?,
          icon: p['icon'] as String?,
          reactions: List<String>.from(p['reactions'] as List),
          reactionCount: p['reaction_count'] as int,
          showBadge: (p['show_badge'] as bool?) ?? false,
        );

    // ── tournament ───────────────────────────────────────────
      case 'tournament':
        return _buildStreakCard(
          name: p['name'] as String,
          avatars: List<String>.from(p['avatars'] as List),
          achievement: p['achievement'] as String,
          days: null,
          icon: p['icon'] as String?,
          reactions: List<String>.from(p['reactions'] as List),
          reactionCount: p['reaction_count'] as int,
          showBadge: (p['show_badge'] as bool?) ?? false,
        );

    // ── activity ─────────────────────────────────────────────
      case 'activity':
        return _buildActivityPost(
          userName: p['user_name'] as String,
          userAvatar: p['user_avatar'] as String,
          timeAgo: _timeAgo(DateTime.parse(
              (p['created_at'] as String?) ?? DateTime.now().toIso8601String())),
          caption: p['caption'] as String,
          stats: Map<String, String>.from(p['stats'] as Map),
          likes: p['likes'] as int,
          comments: p['comments'] as int,
        );

    // ── challenge ────────────────────────────────────────────
      case 'challenge':
        return _buildChallengeCard(
          title: p['title'] as String,
          participants: p['participants'] as int,
          daysLeft: p['days_left'] as int,
          progress: (p['progress'] as num).toDouble(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ── Utility: human-readable time ────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ─────────────────────────────────────────────────────────────
  // Widget templates  (same as before, params only — no hardcoding)
  // ─────────────────────────────────────────────────────────────

  Widget _buildStreakCard({
    required String name,
    required List<String> avatars,
    required String achievement,
    int? days,
    String? icon,
    required List<String> reactions,
    required int reactionCount,
    bool showBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              SizedBox(
                width: avatars.length > 1 ? 60 : 40,
                height: 40,
                child: Stack(
                  children: [
                    for (int i = 0; i < avatars.length; i++)
                      Positioned(
                        left: i * 20.0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: _avatarColor(i),
                          child: Text(
                            avatars[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _text,
                          ),
                        ),
                        if (showBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ELITE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '2h ago',
                      style: TextStyle(fontSize: 12, color: _subText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            achievement,
            style: TextStyle(fontSize: 15, color: _text, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Days badge or emoji icon
          if (days != null)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent.withOpacity(0.8), _accent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    days.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )
          else if (icon != null)
            Text(icon, style: const TextStyle(fontSize: 48)),

          const SizedBox(height: 16),

          // Reactions bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Text('👍 CELEBRATE', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              for (String r in reactions) ...[
                Text(r, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
              ],
              Text(
                reactionCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _subText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPost({
    required String userName,
    required String userAvatar,
    required String timeAgo,
    required String caption,
    required Map<String, String> stats,
    required int likes,
    required int comments,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.orange,
                  child: Text(
                    userAvatar,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _text,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(fontSize: 12, color: _subText),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: _subText),
              ],
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              caption,
              style: TextStyle(fontSize: 14, color: _text, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.grey[800]?.withOpacity(0.5)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats.entries.map((e) {
                  return Column(
                    children: [
                      Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.key,
                        style:
                        TextStyle(fontSize: 11, color: _subText),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
                color: Colors.grey.withOpacity(0.3), height: 1),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(Icons.thumb_up_outlined, likes.toString()),
                _actionButton(
                    Icons.chat_bubble_outline, comments.toString()),
                _actionButton(Icons.share_outlined, 'Share'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required int participants,
    required int daysLeft,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.3), _accent.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _text,
                      ),
                    ),
                    Text(
                      '$participants participants',
                      style:
                      TextStyle(fontSize: 12, color: _subText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
              Text(
                '$daysLeft days left',
                style: TextStyle(fontSize: 12, color: _subText),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join Challenge',
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _text.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style:
              TextStyle(fontSize: 14, color: _text.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(int index) {
    const colors = [
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.pink,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}