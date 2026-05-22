import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fintech/services/xp_service.dart';
import 'widgets/daily_reward_completed_view.dart';

class ShakeWinScreen extends StatefulWidget {
  const ShakeWinScreen({super.key});

  @override
  State<ShakeWinScreen> createState() => _ShakeWinScreenState();
}

class _ShakeWinScreenState extends State<ShakeWinScreen>
    with TickerProviderStateMixin {
  static const _shakeThreshold = 16.0;
  static const _cooldown = Duration(milliseconds: 1200);

  final List<int> _rewards = [50, 100, 200, 300, 500, 800, 1000];
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  int? _reward;
  bool _isReady = true;
  bool _loadingDaily = true;
  bool _playedToday = false;
  late final AnimationController _floatController;
  Animation<double> _tiltAnimation = const AlwaysStoppedAnimation<double>(0);
  late final AnimationController _phoneController;
  Animation<double> _phoneShake = const AlwaysStoppedAnimation<double>(0);

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _tiltAnimation = Tween<double>(
      begin: -math.pi / 6,
      end: math.pi / 6,
    ).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _phoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
    _phoneShake = CurvedAnimation(
      parent: _phoneController,
      curve: Curves.easeInOut,
    );
    _loadDailyStatus();
  }

  Future<void> _loadDailyStatus() async {
    final played = await XpService.instance.hasDailyReward(XpService.shakeWinGame);
    if (!mounted) return;
    setState(() {
      _playedToday = played;
      _loadingDaily = false;
      if (played) {
        _isReady = false;
      }
    });
    if (!played) {
      _subscription = accelerometerEventStream().listen(_onAccelerometer);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _floatController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (_playedToday || !_isReady) return;

    final now = DateTime.now();
    if (now.difference(_lastShake) < _cooldown) return;

    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (magnitude > _shakeThreshold) {
      _lastShake = now;
      _grantReward();
    }
  }

  Future<void> _grantReward() async {
    if (_playedToday || !_isReady) return;

    setState(() => _isReady = false);

    final reward = _rewards[math.Random().nextInt(_rewards.length)];

    try {
      final result = await XpService.instance.earnXpOnce(
        amount: reward,
        source: 'shake_win_reward',
        awardKey: XpService.dailyAwardKey(XpService.shakeWinGame),
      );

      if (!mounted) return;

      if (!result.awarded) {
        setState(() {
          _playedToday = true;
          _reward = null;
        });
        _subscription?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily shake reward already claimed.'),
          ),
        );
        return;
      }

      setState(() {
        _reward = reward;
        _playedToday = true;
      });
      _subscription?.cancel();
    } catch (error) {
      if (!mounted) return;

      setState(() => _isReady = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save reward right now. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A52),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shake & Win',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingDaily
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _playedToday && _reward == null
              ? const DailyRewardCompletedView(
                  gameTitle: 'Shake & Win',
                  accentColor: Color(0xFF8B5CF6),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3F9EB2),
                        Color(0xFF8F94FB),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        _reward == null
                            ? 'Shake your phone\nto earn points!'
                            : 'You earned $_reward XP!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (_reward == null && !_playedToday) ...[
                        const SizedBox(height: 8),
                        Text(
                          'One shake per day',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Expanded(
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.14,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.redeem_rounded, size: 56, color: Colors.white),
                                    SizedBox(height: 20),
                                    Icon(Icons.redeem_rounded, size: 56, color: Colors.white),
                                  ],
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _tiltAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _tiltAnimation.value,
                                    alignment: Alignment.bottomCenter,
                                    child: child,
                                  );
                                },
                                child: SizedBox(
                                  width: 260,
                                  height: 330,
                                  child: Image.asset(
                                    'assets/shake_egg.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _phoneShake,
                        builder: (context, child) {
                          final angle = math.sin(_phoneShake.value * math.pi * 2) * 0.18;
                          return Transform.rotate(
                            angle: angle,
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.phone_iphone_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_reward != null) ...[
                        Text(
                          'Come back tomorrow for another shake!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1A3A52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Back to Rewards',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else if (!_isReady && !_playedToday) ...[
                        const Text(
                          'Processing…',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
