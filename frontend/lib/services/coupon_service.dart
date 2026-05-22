import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum CouponStatus { active, used, expired }

class UserCoupon {
  const UserCoupon({
    required this.id,
    required this.dealStore,
    required this.dealTitle,
    required this.discount,
    required this.description,
    required this.location,
    required this.couponCode,
    required this.validUntil,
    required this.storeLogoUrl,
    required this.status,
    required this.claimedAt,
    required this.xpCost,
    required this.validationPoints,
  });

  static const defaultValidationPoints = [
    'Must be presented to merchant.',
    'Not combinable with other promotions.',
  ];

  final String id;
  final String dealStore;
  final String dealTitle;
  final String discount;
  final String description;
  final String location;
  final String couponCode;
  final DateTime validUntil;
  final String storeLogoUrl;
  final CouponStatus status;
  final DateTime claimedAt;
  final int xpCost;
  final List<String> validationPoints;

  bool get isExpiredByDate =>
      status == CouponStatus.active && validUntil.isBefore(DateTime.now());

  CouponStatus get effectiveStatus {
    if (status == CouponStatus.used) return CouponStatus.used;
    if (status == CouponStatus.expired || isExpiredByDate) {
      return CouponStatus.expired;
    }
    return CouponStatus.active;
  }

  factory UserCoupon.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final validUntil = (data['validUntil'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 30));
    final claimedAt = (data['claimedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return UserCoupon(
      id: doc.id,
      dealStore: data['dealStore'] as String? ?? '',
      dealTitle: data['dealTitle'] as String? ?? '',
      discount: data['discount'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      couponCode: data['couponCode'] as String? ?? '',
      validUntil: validUntil,
      storeLogoUrl: data['storeLogoUrl'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      claimedAt: claimedAt,
      xpCost: (data['xpCost'] as num?)?.toInt() ?? 0,
      validationPoints: _parseValidationPoints(data['validationPoints']),
    );
  }

  static List<String> _parseValidationPoints(dynamic value) {
    if (value is List) {
      final points = value
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return points.isEmpty ? defaultValidationPoints : points;
    }
    return defaultValidationPoints;
  }

  static CouponStatus _parseStatus(String? value) {
    switch (value) {
      case 'used':
        return CouponStatus.used;
      case 'expired':
        return CouponStatus.expired;
      default:
        return CouponStatus.active;
    }
  }

  static String statusToString(CouponStatus status) {
    switch (status) {
      case CouponStatus.used:
        return 'used';
      case CouponStatus.expired:
        return 'expired';
      case CouponStatus.active:
        return 'active';
    }
  }
}

class CouponService {
  CouponService._();

  static final CouponService instance = CouponService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _couponsRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('coupons');
  }

  Stream<List<UserCoupon>> couponsStream() {
    final ref = _couponsRef();
    if (ref == null) {
      return Stream.value(const []);
    }

    return ref.orderBy('claimedAt', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(UserCoupon.fromFirestore).toList(),
        );
  }

  Stream<int> activeCouponCountStream() {
    return couponsStream().map(
      (coupons) => coupons
          .where((c) => c.effectiveStatus == CouponStatus.active)
          .length,
    );
  }

  Future<void> deleteCoupon(String couponId) async {
    final ref = _couponsRef();
    if (ref == null) return;
    await ref.doc(couponId).delete();
  }

  Future<UserCoupon> claimCoupon({
    required String dealStore,
    required String dealTitle,
    required String discount,
    required String description,
    required String location,
    required String storeLogoUrl,
    required int xpCost,
    List<String> validationPoints = UserCoupon.defaultValidationPoints,
    Duration validity = const Duration(days: 30),
  }) async {
    final ref = _couponsRef();
    if (ref == null) {
      throw StateError('User must be logged in to claim a coupon.');
    }

    final couponCode = _generateCouponCode();
    final validUntil = DateTime.now().add(validity);
    final docRef = ref.doc();

    final payload = {
      'dealStore': dealStore,
      'dealTitle': dealTitle,
      'discount': discount,
      'description': description,
      'location': location,
      'couponCode': couponCode,
      'validUntil': Timestamp.fromDate(validUntil),
      'storeLogoUrl': storeLogoUrl,
      'status': UserCoupon.statusToString(CouponStatus.active),
      'xpCost': xpCost,
      'validationPoints': validationPoints,
      'claimedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(payload);

    return UserCoupon(
      id: docRef.id,
      dealStore: dealStore,
      dealTitle: dealTitle,
      discount: discount,
      description: description,
      location: location,
      couponCode: couponCode,
      validUntil: validUntil,
      storeLogoUrl: storeLogoUrl,
      status: CouponStatus.active,
      claimedAt: DateTime.now(),
      xpCost: xpCost,
      validationPoints: validationPoints,
    );
  }

  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
