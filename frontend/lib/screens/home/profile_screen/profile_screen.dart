import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onIndexChanged;

  const ProfileScreen({
    super.key,
    this.onIndexChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _xpPerLevel = 500;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await _auth.signOut();
      if (!mounted) return;
      widget.onIndexChanged?.call(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to logout. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final userStream = user == null
        ? Stream<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
        : _firestore.collection('users').doc(user.uid).snapshots().map((doc) => doc);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: const Center(child: CircularProgressIndicator()),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'We could not load your profile right now. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        }

        if (user == null) {
          return Scaffold(
            body: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'You are not signed in.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final currentXp = (data['xp'] as num?)?.toInt() ?? 0;
        final firstName = (data['firstName'] as String?)?.trim() ?? '';
        final lastName = (data['lastName'] as String?)?.trim() ?? '';
        final emailFallback = (user.email ?? '').split('@').first.trim();
        final displayName = [firstName, lastName]
            .where((part) => part.isNotEmpty)
            .join(' ')
            .trim();
        final streakDays = (data['streakDays'] as num?)?.toInt() ?? 0;
        final savedAmount = (data['savedAmount'] as num?)?.toDouble() ?? 0;
        final lessonsCompleted = (data['lessonsCompleted'] as num?)?.toInt() ?? 12;
        final goalsCount = (data['goalsCount'] as num?)?.toInt() ?? 3;

        final createdAtRaw = data['createdAt'];
        final createdAt = createdAtRaw is Timestamp ? createdAtRaw : null;
        final memberSince = _formatMemberSince(createdAt);

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Blue Background
                _buildProfileHeader(
                  displayName: displayName.isEmpty
                      ? (emailFallback.isEmpty ? 'User' : emailFallback)
                      : displayName,
                  streakDays: streakDays,
                  memberSince: memberSince,
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Stats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Level and Stats Section
                _buildLevelAndStatsSection(currentXp),
                const SizedBox(height: 20),
                // Stats Cards (XP, Lessons, Goals, Saved)
                _buildStatsCardsSection(
                  totalXp: currentXp,
                  savedAmount: savedAmount,
                  lessonsCompleted: lessonsCompleted,
                  goalsCount: goalsCount,
                ),
                const SizedBox(height: 24),
                // Emergency Fund Goal Card
                _buildEmergencyFundCard(),
                const SizedBox(height: 20),
                // Smart Insight Card
                _buildSmartInsightCard(),
                const SizedBox(height: 32),
                // Settings & Preferences Section
                _buildSettingsPreferencesSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildProfileHeader({
    required String displayName,
    required int streakDays,
    required String memberSince,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1488FF), Color(0xFF0067DD)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331488FF),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -26,
                bottom: -34,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            icon: const Icon(Icons.share_outlined, color: Colors.white),
                            onPressed: () => _showComingSoon('Share profile'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/profile_avatar.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withValues(alpha: 0.85),
                              child: const Icon(Icons.person, color: Color(0xFF6E7EA7), size: 38),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, size: 19, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '$streakDays Day Streak',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Member since: $memberSince',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelAndStatsSection(int totalXp) {
    final currentLevel = (totalXp ~/ _xpPerLevel) + 1;
    final xpInCurrentLevel = totalXp % _xpPerLevel;
    final progress = xpInCurrentLevel / _xpPerLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF4D9),
                ),
                child: const Icon(Icons.emoji_events, size: 24, color: Color(0xFFFFB020)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $currentLevel Explorer',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xpInCurrentLevel / $_xpPerLevel XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F80ED),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F80ED),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFEAEFF7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardsSection({
    required int totalXp,
    required double savedAmount,
    required int lessonsCompleted,
    required int goalsCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            icon: Icons.bolt,
            label: 'XP',
            value: _formatNumber(totalXp),
            backgroundColor: const Color(0xFFE8F3FF),
          ),
          _buildStatCard(
            icon: Icons.school_outlined,
            label: 'Lessons',
            value: _formatNumber(lessonsCompleted),
            backgroundColor: const Color(0xFFE8F3FF),
          ),
          _buildStatCard(
            icon: Icons.flag_outlined,
            label: 'Goals',
            value: _formatNumber(goalsCount),
            backgroundColor: const Color(0xFFE8F3FF),
          ),
          _buildStatCard(
            icon: Icons.savings_outlined,
            label: 'Saved',
            value: _formatCurrency(savedAmount),
            backgroundColor: const Color(0xFFE8F3FF),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _formatCurrency(double amount) {
    return 'Rs ${_formatNumber(amount.round())}';
  }

  String _formatMemberSince(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final date = timestamp.toDate();
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF007AFF), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.58),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyFundCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F8CFF), Color(0xFF0067DD)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26007AFF),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Goal Label
          Text(
            'TOP GOAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.74),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Goal Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency Fund',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 36,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.savings_outlined, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Amount
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Rs 4,000 ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: '/ Rs 10,000',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0.4, // 4000/10000
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.34),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsightCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.12),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.trending_up, size: 16, color: Color(0xFF007AFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Insight:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.58),
                    ),
                    children: [
                      const TextSpan(text: 'Your savings consistency improved by '),
                      const TextSpan(
                        text: '14%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                      const TextSpan(text: ' this month'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.person_outline,
            label: 'Account',
            onTap: () => _showComingSoon('Account'),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => _showComingSoon('Notifications'),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.tune_outlined,
            label: 'Preferences',
            onTap: () => _showComingSoon('Preferences'),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.help_outline,
            label: 'Help Center',
            onTap: () => _showComingSoon('Help Center'),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: _handleLogout,
            isRed: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isRed = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9EEF6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isRed ? Colors.red : const Color(0xFF42526B),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isRed ? Colors.red : const Color(0xFF253247),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.black.withValues(alpha: 0.22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          widget.onIndexChanged?.call(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color.fromRGBO(0, 0, 0, 0.55),
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined, size: 24),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined, size: 24),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_outlined, size: 24),
            label: 'Deals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
