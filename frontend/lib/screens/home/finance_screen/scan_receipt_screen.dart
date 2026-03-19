import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  CameraController? _cameraController;

  bool _isCameraReady = false;
  bool _showReview = false;
  bool _flashOn = false;
  bool _isProcessing = false;

  String _paidWith = 'wallet'; // wallet or cash
  String _category = 'Food & Dining';
  IconData _categoryIcon = Icons.restaurant;
  double _amount = 0.0;
  String _date = 'Today';
  String _merchantName = 'Unknown Merchant';

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      debugPrint('Available cameras: ${cameras.length}');

      if (cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      debugPrint('Camera error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera unavailable on this device')),
      );
    }
  }

  Future<void> _captureAndScanReceipt() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera is not ready')),
      );
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _showReview = false;
    });

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final XFile image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final extractedText = recognizedText.text;
      debugPrint('OCR TEXT:\n$extractedText');

      final detectedAmount = _extractAmount(extractedText);
      final detectedDate = _extractDate(extractedText);
      final detectedMerchant = _extractMerchant(extractedText);
      final detectedCategory = _detectCategory(extractedText);

      if (!mounted) return;

      setState(() {
        _amount = detectedAmount ?? 0.0;
        _date = detectedDate ?? 'Today';
        _merchantName = detectedMerchant;
        _category = detectedCategory['label'] as String;
        _categoryIcon = detectedCategory['icon'] as IconData;
        _showReview = true;
      });
    } catch (e) {
      debugPrint('Scan error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan receipt')),
      );
    } finally {
      await textRecognizer.close();
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  double? _extractAmount(String text) {
    final normalized = text.replaceAll('\n', ' ');

    final primaryRegex = RegExp(
      r'(grand total|total amount|total|amount due|amount|subtotal)[^\d]{0,20}(\d+[.,]\d{2})',
      caseSensitive: false,
    );

    final primaryMatches = primaryRegex.allMatches(normalized).toList();
    if (primaryMatches.isNotEmpty) {
      final value = primaryMatches.last.group(2)?.replaceAll(',', '.');
      return double.tryParse(value ?? '');
    }

    final moneyRegex = RegExp(r'\b\d+[.,]\d{2}\b');
    final values = moneyRegex
        .allMatches(normalized)
        .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')) ?? 0.0)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return null;

    values.sort();
    return values.last;
  }

  String? _extractDate(String text) {
    final dateRegex = RegExp(
      r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b',
      caseSensitive: false,
    );

    final match = dateRegex.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }

    return 'Today';
  }

  String _extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) return 'Unknown Merchant';

    final blacklist = [
      'receipt',
      'invoice',
      'tax invoice',
      'date',
      'time',
      'total',
      'subtotal',
      'cashier',
      'vat',
      'amount',
    ];

    for (final line in lines.take(5)) {
      final lower = line.toLowerCase();
      final looksBad = blacklist.any((word) => lower.contains(word));
      if (!looksBad && line.length > 2) {
        return line;
      }
    }

    return lines.first;
  }

  Map<String, dynamic> _detectCategory(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('restaurant') ||
        lower.contains('cafe') ||
        lower.contains('food') ||
        lower.contains('burger') ||
        lower.contains('pizza') ||
        lower.contains('coffee') ||
        lower.contains('dining')) {
      return {'label': 'Food & Dining', 'icon': Icons.restaurant};
    }

    if (lower.contains('bus') ||
        lower.contains('taxi') ||
        lower.contains('transport') ||
        lower.contains('petrol') ||
        lower.contains('fuel') ||
        lower.contains('metro')) {
      return {'label': 'Transport', 'icon': Icons.directions_car};
    }

    if (lower.contains('cinema') ||
        lower.contains('movie') ||
        lower.contains('ticket') ||
        lower.contains('gaming')) {
      return {'label': 'Entertainment', 'icon': Icons.confirmation_number};
    }

    if (lower.contains('bill') ||
        lower.contains('electricity') ||
        lower.contains('water') ||
        lower.contains('internet') ||
        lower.contains('utility')) {
      return {'label': 'Bills', 'icon': Icons.receipt_long};
    }

    return {'label': 'Shopping', 'icon': Icons.shopping_bag};
  }

  Future<void> _saveScannedTransaction() async {
    debugPrint('Saving transaction...');
    debugPrint('Merchant: $_merchantName');
    debugPrint('Amount: $_amount');
    debugPrint('Category: $_category');
    debugPrint('Date: $_date');
    debugPrint('Paid with: $_paidWith');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved')),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewSize = _cameraController?.value.previewSize;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraReady && _cameraController != null && previewSize != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: previewSize.height,
                  height: previewSize.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2, top: 2),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Receipt Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 48),
                      child: AspectRatio(
                        aspectRatio: 0.75,
                        child: CustomPaint(
                          painter: _ViewfinderPainter(),
                          child: AnimatedBuilder(
                            animation: _scanLineController,
                            builder: (context, child) {
                              return Stack(
                                children: [
                                  Positioned(
                                    top: _scanLineController.value *
                                        (MediaQuery.of(context).size.width - 96) /
                                        0.75 *
                                        0.6,
                                    left: 10,
                                    right: 10,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            const Color(0xFF007AFF).withOpacity(0.8),
                                            const Color(0xFF007AFF),
                                            const Color(0xFF007AFF).withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF007AFF).withOpacity(0.5),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 24,
                      bottom: 110,
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            _flashOn = !_flashOn;
                          });

                          if (_cameraController != null && _isCameraReady) {
                            await _cameraController!.setFlashMode(
                              _flashOn ? FlashMode.torch : FlashMode.off,
                            );
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _flashOn
                                ? const Color(0xFF007AFF)
                                : Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!_showReview)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndScanReceipt,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 4,
                      ),
                    ),
                    child: _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 30,
                          ),
                  ),
                ),
              ),
            ),

          if (_showReview)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildReviewSheet(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Review Transaction',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MERCHANT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _merchantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AMOUNT DETECTED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rs ${_amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showEditAmountDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECECEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CATEGORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8E8E93),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                _categoryIcon,
                                color: const Color(0xFF8E8E93),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _category,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showCategoryPicker,
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Color(0xFF007AFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECECEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DATE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8E8E93),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF8E8E93),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _date,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showDatePickerCustom,
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                color: Color(0xFF007AFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAID WITH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          _buildPaymentToggle('Wallet', 'wallet'),
                          _buildPaymentToggle('Cash', 'cash'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _paidWith == 'wallet'
                          ? 'Wallet deducts from your digital balance. Cash logs as budget expense.'
                          : 'Cash logs as budget expense. Wallet deducts from your digital balance.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await _saveScannedTransaction();
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _showReview = false;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Cancel Scan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentToggle(String label, String value) {
    final isSelected = _paidWith == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paidWith = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAmountDialog() {
    final controller = TextEditingController(
      text: _amount == 0 ? '' : _amount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: 'Rs ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newAmount = double.tryParse(controller.text.trim());
              if (newAmount != null) {
                setState(() {
                  _amount = newAmount;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = [
      {'label': 'Food & Dining', 'icon': Icons.restaurant},
      {'label': 'Transport', 'icon': Icons.directions_car},
      {'label': 'Shopping', 'icon': Icons.shopping_bag},
      {'label': 'Bills', 'icon': Icons.receipt_long},
      {'label': 'Entertainment', 'icon': Icons.confirmation_number},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((c) {
              return ListTile(
                leading: Icon(
                  c['icon'] as IconData,
                  color: const Color(0xFF007AFF),
                ),
                title: Text(c['label'] as String),
                onTap: () {
                  setState(() {
                    _category = c['label'] as String;
                    _categoryIcon = c['icon'] as IconData;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePickerCustom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      final now = DateTime.now();
      final isToday = picked.day == now.day &&
          picked.month == now.month &&
          picked.year == now.year;

      setState(() {
        _date = isToday
            ? 'Today'
            : '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cornerPaint = Paint()
      ..color = const Color(0xFF007AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const radius = Radius.circular(12);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    canvas.drawRRect(rrect, paint);

    const cornerLength = 30.0;

    canvas.drawLine(
      Offset(0, cornerLength),
      const Offset(0, 12),
      cornerPaint,
    );
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, 24, 24),
      pi,
      pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(12, 0),
      Offset(cornerLength, 0),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width - 12, 0),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - 24, 0, 24, 24),
      -pi / 2,
      pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 12),
      Offset(size.width, cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height - 12),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - 24, 24, 24),
      pi / 2,
      pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(12, size.height),
      Offset(cornerLength, size.height),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width - 12, size.height),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - 24, size.height - 24, 24, 24),
      0,
      pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - 12),
      Offset(size.width, size.height - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}