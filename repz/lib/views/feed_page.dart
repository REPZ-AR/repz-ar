import 'package:flutter/material.dart';

class FeedPage extends StatefulWidget {
  final bool isDarkMode;

  const FeedPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
    final backgroundColor = widget.isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Feed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: textColor),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: secondaryTextColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedContent(
            accentColor: accentColor,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildFollowingContent(
            accentColor: accentColor,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent({
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color? secondaryTextColor,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak Achievement Card
        _buildStreakCard(
          name: 'David and Alana',
          avatars: ['D', 'A'],
          achievement: 'Reached a 475 day Friend Streak!',
          days: 475,
          reactions: ['🎉', '💪', '😊'],
          reactionCount: 12742,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 16),

        // Tournament Achievement
        _buildStreakCard(
          name: 'Paula',
          avatars: ['P'],
          achievement: 'Won the Diamond Tournament Finale 9 times!',
          icon: '💎',
          reactions: ['🎉', '💪', '😊'],
          reactionCount: 3412,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 16),

        // Workout Milestone
        _buildStreakCard(
          name: 'HB',
          avatars: ['H'],
          achievement: 'Reached a DuoLingo Streak of 29!',
          days: 29,
          reactions: ['🎉', '💪', '😊'],
          reactionCount: 892,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          showBadge: true,
        ),
        const SizedBox(height: 16),

        // Activity Post
        _buildActivityPost(
          userName: 'Sarah Mitchell',
          userAvatar: 'S',
          timeAgo: '2h ago',
          caption: 'Morning grind! 💪 Hit a new PR on deadlifts today - 315lbs! Feeling stronger every day.',
          imagePath: null,
          stats: {
            'Duration': '1h 15m',
            'Calories': '420 kcal',
            'PR': 'Deadlift 315lbs',
          },
          likes: 87,
          comments: 12,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 16),

        // Challenge card
        _buildChallengeCard(
          title: '30-Day Push-Up Challenge',
          participants: 1247,
          daysLeft: 12,
          progress: 0.6,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 16),

        // Another Activity
        _buildActivityPost(
          userName: 'Mike Johnson',
          userAvatar: 'M',
          timeAgo: '5h ago',
          caption: 'Leg day complete! 🦵 Nothing beats that post-workout feeling.',
          imagePath: null,
          stats: {
            'Duration': '50m',
            'Exercises': '8 sets',
            'Calories': '380 kcal',
          },
          likes: 54,
          comments: 8,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 16),

        // Streak milestone
        _buildStreakCard(
          name: 'Emma & Jake',
          avatars: ['E', 'J'],
          achievement: 'Completed 100 workouts together this year!',
          days: 100,
          reactions: ['🎉', '🔥', '💪'],
          reactionCount: 234,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildFollowingContent({
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color? secondaryTextColor,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActivityPost(
          userName: 'Alex Torres',
          userAvatar: 'A',
          timeAgo: '1h ago',
          caption: 'Early morning run before the gym! 🏃‍♂️ The sunrise was incredible.',
          imagePath: null,
          stats: {
            'Distance': '5.2 km',
            'Pace': '5:30 /km',
            'Time': '28m 36s',
          },
          likes: 42,
          comments: 5,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 16),

        _buildActivityPost(
          userName: 'Jessica Park',
          userAvatar: 'J',
          timeAgo: '3h ago',
          caption: 'New yoga routine unlocked! Feeling zen and flexible 🧘‍♀️',
          imagePath: null,
          stats: {
            'Duration': '45m',
            'Type': 'Vinyasa Flow',
            'Calories': '180 kcal',
          },
          likes: 67,
          comments: 9,
          accentColor: accentColor,
          cardColor: cardColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildStreakCard({
    required String name,
    required List<String> avatars,
    required String achievement,
    int? days,
    String? icon,
    required List<String> reactions,
    required int reactionCount,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color? secondaryTextColor,
    bool showBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
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
          // Header with avatars and name
          Row(
            children: [
              // Avatars
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
                          backgroundColor: _getAvatarColor(i),
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
                            color: textColor,
                          ),
                        ),
                        if (showBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ELITE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '2h ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Achievement text
          Text(
            achievement,
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Days badge or icon
          if (days != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.8),
                    accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 24),
                  ),
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
            Text(
              icon,
              style: const TextStyle(fontSize: 48),
            ),
          const SizedBox(height: 16),

          // Reactions bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('👍 CELEBRATE', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Reaction emojis
              for (String reaction in reactions) ...[
                Text(reaction, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
              ],
              Text(
                reactionCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
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
    String? imagePath,
    required Map<String, String> stats,
    required int likes,
    required int comments,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color? secondaryTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
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
                          color: textColor,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: secondaryTextColor),
              ],
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              caption,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
              ),
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
                children: stats.entries.map((entry) {
                  return Column(
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.grey.withOpacity(0.3),
              height: 1,
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.thumb_up_outlined,
                  label: likes.toString(),
                  textColor: textColor,
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: comments.toString(),
                  textColor: textColor,
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  textColor: textColor,
                ),
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
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color? secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.3),
            accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.black,
                  size: 24,
                ),
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
                        color: textColor,
                      ),
                    ),
                    Text(
                      '$participants participants',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                  color: textColor,
                ),
              ),
              Text(
                '$daysLeft days left',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Join button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join Challenge',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color textColor,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.pink,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}

