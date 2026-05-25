import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fintech/services/auth_service.dart';
import 'package:fintech/services/app_theme_controller.dart';
import 'package:fintech/services/xp_service.dart';
import 'package:fintech/screens/auth/login_screen.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

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
      await _authService.logoutUser();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => const LoginScreen(showLoggedOutMessage: true),
        ),
        (route) => false,
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
        : _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .map((doc) => doc);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'We could not load your profile right now. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (user == null) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'You are not signed in.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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
        final levelMeta = XpService.levelMetaFromTotalXp(currentXp);
        final currentLevel = levelMeta.level;

        final createdAtRaw = data['createdAt'];
        final createdAt = createdAtRaw is Timestamp ? createdAtRaw : null;
        final memberSince = _formatMemberSince(createdAt);

        return Scaffold(
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section with Blue Background
                _buildProfileHeader(
                  displayName: displayName.isEmpty
                      ? (emailFallback.isEmpty ? 'User' : emailFallback)
                      : displayName,
                  memberSince: memberSince,
                ),
                const SizedBox(height: 20),
                _buildStatsCardsSection(
                  streakDays: streakDays,
                  level: currentLevel,
                  totalXp: currentXp,
                ),
                const SizedBox(height: 12),
                _buildLevelProgressSection(
                  level: currentLevel,
                  currentXp: currentXp,
                ),
                const SizedBox(height: 24),
                // Settings & Preferences Section
                _buildSettingsPreferencesSection(data),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () {
          Navigator.maybePop(context);
        },
      ),
      title: const Text('Profile'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF17192B) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
    );
  }

  Future<void> _openAccountSettings({
    required String currentFirstName,
    required String currentLastName,
    required String currentEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final fullName = [currentFirstName, currentLastName]
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
    final usernameController = TextEditingController(
      text: fullName.isEmpty ? currentEmail.split('@').first : fullName,
    );

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    String gender = (userData['gender'] as String?) ?? 'Prefer not to say';

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
            final secondaryText = isDark
                ? Colors.white.withValues(alpha: 0.82)
                : Colors.black.withValues(alpha: 0.62);
            final iconColor =
                isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.55);
            final hintText =
                isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.38);
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1020) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Edit Personal Details',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, false),
                              icon: Icon(Icons.close, color: iconColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Username',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBottomSheetField(
                          child: TextField(
                            controller: usernameController,
                            style: TextStyle(color: primaryText),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter username',
                              hintStyle: TextStyle(color: hintText),
                              prefixIcon:
                                  Icon(Icons.person_outline, color: iconColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Gender',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGenderChip(
                                    label: 'Male',
                                    selected: gender == 'Male',
                                    onTap: () =>
                                        setSheetState(() => gender = 'Male'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildGenderChip(
                                    label: 'Female',
                                    selected: gender == 'Female',
                                    onTap: () =>
                                        setSheetState(() => gender = 'Female'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: _buildGenderChip(
                                label: 'Prefer not to say',
                                selected: gender == 'Prefer not to say',
                                onTap: () => setSheetState(
                                  () => gender = 'Prefer not to say',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1F8CFF), Color(0xFF0067DD)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () => Navigator.pop(sheetContext, true),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (shouldSave != true) return;

    final fullNameSaved = usernameController.text.trim();
    final splitName = fullNameSaved.split(RegExp(r'\s+'));
    final firstName = splitName.isEmpty ? '' : splitName.first;
    final lastName = splitName.length > 1 ? splitName.sublist(1).join(' ') : '';

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal details updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save personal details')),
      );
    }
  }

  Future<void> _openNotificationSettings({
    required bool pushEnabled,
    required bool emailEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    bool pushValue = pushEnabled;
    bool emailValue = emailEnabled;

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0F1020)
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Push notifications',
                          style: TextStyle(color: primaryText)),
                      value: pushValue,
                      onChanged: (value) =>
                          setDialogState(() => pushValue = value),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Email updates',
                          style: TextStyle(color: primaryText)),
                      value: emailValue,
                      onChanged: (value) =>
                          setDialogState(() => emailValue = value),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F8CFF), Color(0xFF0067DD)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Save',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (shouldSave != true) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'notifications': {
          'push': pushValue,
          'email': emailValue,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences saved')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save notification settings')),
      );
    }
  }

  Future<void> _openAccountSecurity() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    final refreshedUser = _auth.currentUser ?? user;
    final providerIds =
        refreshedUser.providerData.map((info) => info.providerId).toSet();
    final hasPasswordProvider = providerIds.contains('password');
    final providerLabel = providerIds.contains('google.com')
        ? 'Google'
        : hasPasswordProvider
            ? 'Email and password'
            : 'External provider';

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
            final secondaryText =
                isDark ? const Color(0xFFAAB0C6) : const Color(0xFF64748B);

            return Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1020) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Account Security',
                      style: TextStyle(
                          color: primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Signed in with $providerLabel',
                      style: TextStyle(color: secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (hasPasswordProvider)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(sheetContext, 'resetPassword'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF007AFF)),
                            foregroundColor: primaryText,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Send password reset email'),
                        ),
                      ),
                    if (!hasPasswordProvider)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF17192B)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                const Color(0xFF007AFF).withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          'Password reset emails are only available for email/password accounts. Manage your password through $providerLabel.',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (!hasPasswordProvider)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF1F8CFF), Color(0xFF0067DD)]),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Close',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    if (result == 'resetPassword') {
      final email = refreshedUser.email;
      if (email == null || email.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found for this account')),
        );
        return;
      }
      try {
        await _auth.sendPasswordResetEmail(email: email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email')),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        final message = switch (e.code) {
          'user-not-found' => 'No email/password account exists for $email',
          'invalid-email' => 'This account email is invalid.',
          'too-many-requests' => 'Too many attempts. Try again later.',
          _ => e.message ?? 'Unable to send password reset email',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to send password reset email')),
        );
      }
      return;
    }
  }

  Future<void> _openAppPreferences({
    required String currentLanguage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String languageValue = currentLanguage;
    String themeLabel = AppThemeController.labelForThemeMode(
        AppThemeController.modeNotifier.value);
    String fontLabel = AppThemeController.labelForTextScale(
        AppThemeController.linearTextScale);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Preferences'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: languageValue,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: const [
                      DropdownMenuItem(
                          value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Urdu', child: Text('Urdu')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => languageValue = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: themeLabel,
                    decoration: const InputDecoration(labelText: 'Appearance'),
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                      DropdownMenuItem(
                          value: 'system', child: Text('Use system setting')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => themeLabel = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: fontLabel,
                    decoration: const InputDecoration(labelText: 'Font size'),
                    items: const [
                      DropdownMenuItem(value: 'small', child: Text('Small')),
                      DropdownMenuItem(
                          value: 'default', child: Text('Default')),
                      DropdownMenuItem(value: 'large', child: Text('Large')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => fontLabel = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) return;

    try {
      final themeMode = AppThemeController.themeModeFromLabel(themeLabel);
      final textLinear = AppThemeController.linearScaleFromLabel(fontLabel);
      await AppThemeController.setThemeMode(themeMode);
      await AppThemeController.setTextLinearScale(textLinear);

      await _firestore.collection('users').doc(user.uid).set({
        'preferences': {
          'language': languageValue,
          'themeMode': themeLabel,
          'fontSize': fontLabel,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save preferences')),
      );
    }
  }

  Future<void> _openFaq() async {
    final questions = <Map<String, String>>[
      {
        'q': 'Who is Monéo for?',
        'a':
            'Monéo is for young adults who want to build better financial habits.',
      },
      {
        'q': 'How does earning XP work?',
        'a': 'You earn XP by completing lessons, quizzes, and daily actions.',
      },
      {
        'q': 'What are streaks?',
        'a': 'Streaks track how many days in a row you stay active in the app.',
      },
      {
        'q': 'How do lessons and quizzes work?',
        'a':
            'Lessons teach one financial topic at a time. Some topics include a quick pre-quiz, then learning content, then a final quiz. Completing lessons and quizzes can earn XP.',
      },
      {
        'q': 'Do I earn XP if I repeat a lesson?',
        'a':
            'No. XP is awarded only the first time you complete a lesson, quiz, or reward action. You can repeat content to review it, but duplicate completions do not give extra XP.',
      },
      {
        'q': 'What are Deals and rewards?',
        'a':
            'Deals include coupons, rewards, and mini-games like Spin & Win, Guess & Win, and Shake & Win. Some rewards can give XP or unlock deal-related benefits.',
      },
      {
        'q': 'What is Ask Miro?',
        'a':
            'Ask Miro is your in-app learning assistant. You can use it to ask simple money questions, understand lessons, and get guidance while using Monéo. It is for education only and does not replace professional financial advice.',
      },
      {
        'q': 'How do I reset my password?',
        'a':
            'Go to Profile > Account Security and tap Send password reset email. This works for email/password accounts. If you signed in with Google, manage your password through Google.',
      },
      {
        'q': 'Is my financial data real banking data?',
        'a':
            'No. Monéo is a financial literacy app. Wallets, cards, bill payments, QR scans, and finance tools are for learning and simulation unless clearly connected to a real provider.',
      },
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
        final secondaryText = isDark
            ? Colors.white.withValues(alpha: 0.82)
            : Colors.black.withValues(alpha: 0.62);
        final iconColor =
            isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.55);
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1020) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'FAQ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: primaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close, color: iconColor),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = questions[index];
                      return Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1B1D33)
                                : const Color(0xFFF3F6FB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              '${index + 1}. ${item['q']!}',
                              style:
                                  TextStyle(color: primaryText, fontSize: 18),
                            ),
                            iconColor: iconColor,
                            collapsedIconColor: iconColor,
                            childrenPadding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item['a']!,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAbout() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
        final secondaryText = isDark
            ? Colors.white.withValues(alpha: 0.88)
            : Colors.black.withValues(alpha: 0.62);
        final iconColor =
            isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.55);
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F1020)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'About App',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: primaryText,
                              fontSize: 24,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close, color: iconColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Monéo is a gamified financial literacy app that helps young adults learn money skills through interactive lessons, quizzes, and real-world tools.',
                    style: TextStyle(
                        color: secondaryText, fontSize: 16, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'From budgeting and saving to banking and investing basics, Monéo makes financial education practical and engaging.',
                    style: TextStyle(
                        color: secondaryText, fontSize: 16, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Stay motivated with XP, streaks, and progress tracking while building habits that support your financial goals.',
                    style: TextStyle(
                        color: secondaryText, fontSize: 16, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetField({
    required Widget child,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1B1D33) : const Color(0xFFF3F6FB),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGenderChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? (selected ? const Color(0xFF1B1D33) : const Color(0xFF14162A))
              : (selected
                  ? const Color(0xFF007AFF).withValues(alpha: 0.12)
                  : const Color(0xFFF3F6FB)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF007AFF) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isDark
                  ? (selected ? Colors.white : Colors.white70)
                  : (selected
                      ? const Color(0xFF0F172A)
                      : Colors.black.withValues(alpha: 0.62)),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader({
    required String displayName,
    required String memberSince,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A2D4A)
                        : const Color(0xFFDFE6F1),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/profile_avatar.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark
                            ? const Color(0xFF242742)
                            : const Color(0xFFF3F6FB),
                        child: const Icon(Icons.person,
                            color: Color(0xFF6E7EA7), size: 52),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Material(
                  color: const Color(0xFF007AFF),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showComingSoon('Edit profile'),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Member since: $memberSince',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white70
                  : Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardsSection({
    required int streakDays,
    required int level,
    required int totalXp,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '$streakDays day${streakDays == 1 ? '' : 's'}',
            backgroundColor:
                isDark ? const Color(0xFF1B1D33) : const Color(0xFFFFF1E8),
            iconColor: const Color(0xFFF97316),
          ),
          _buildStatCard(
            icon: Icons.star_rounded,
            label: 'Level',
            value: '$level',
            backgroundColor:
                isDark ? const Color(0xFF1B1D33) : const Color(0xFFF2E8FF),
            iconColor: const Color(0xFF007AFF),
          ),
          _buildStatCard(
            icon: Icons.bolt_rounded,
            label: 'XP',
            value: _formatNumber(totalXp),
            backgroundColor:
                isDark ? const Color(0xFF1B1D33) : const Color(0xFFE8F3FF),
            iconColor: const Color(0xFF2563EB),
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
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? const Color(0xFF2A2D4A) : Colors.white),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFAAB0C6)
                    : Colors.black.withValues(alpha: 0.58),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgressSection({
    required int level,
    required int currentXp,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = XpService.levelMetaFromTotalXp(currentXp);
    final xpIntoLevel = meta.xpIntoLevel;
    final xpRequired = meta.xpRequiredForLevel;
    final progress = meta.progressInLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D33) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE7EAF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Level $level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '${_formatNumber(xpIntoLevel)} / ${_formatNumber(xpRequired)} XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFAAB0C6)
                      : Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFF007AFF).withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
        ],
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
                child: const Icon(Icons.savings_outlined,
                    color: Colors.white, size: 20),
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
            child: const Icon(Icons.trending_up,
                size: 16, color: Color(0xFF007AFF)),
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
                      const TextSpan(
                          text: 'Your savings consistency improved by '),
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

  Widget _buildSettingsPreferencesSection(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;
    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ?? '';
    final notifications = data['notifications'] as Map<String, dynamic>?;
    final preferences = data['preferences'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.person_outline,
            label: 'Edit Personal Details',
            onTap: () => _openAccountSettings(
              currentFirstName: firstName,
              currentLastName: lastName,
              currentEmail: user?.email ?? '-',
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => _openNotificationSettings(
              pushEnabled: notifications?['push'] as bool? ?? true,
              emailEnabled: notifications?['email'] as bool? ?? false,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.shield_outlined,
            label: 'Account Security',
            onTap: _openAccountSecurity,
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.tune_outlined,
            label: 'Preferences',
            onTap: () => _openAppPreferences(
              currentLanguage: preferences?['language'] as String? ?? 'English',
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.help_outline,
            label: 'FAQ',
            onTap: _openFaq,
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.error_outline,
            label: 'About App',
            onTap: _openAbout,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1B1D33) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF2A2D4A) : const Color(0xFFE7EAF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
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
                color: isRed
                    ? const Color(0xFFE64980)
                    : (isDark
                        ? const Color(0xFFAAB0C6)
                        : const Color(0xFF4A5873)),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isRed
                      ? const Color(0xFFE64980)
                      : (isDark ? Colors.white : const Color(0xFF1C2738)),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color:
                    isDark ? const Color(0xFF939BB6) : const Color(0xFF7C879A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
