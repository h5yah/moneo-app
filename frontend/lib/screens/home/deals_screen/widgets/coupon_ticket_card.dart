import 'package:flutter/material.dart';

class CouponTicketCard extends StatelessWidget {
  final String storeName;
  final String dealTitle;
  final String validity;
  final String status; // 'active', 'used', 'expired'
  final Color storeColor;
  final String storeInitials;
  final VoidCallback onTap;

  const CouponTicketCard({
    super.key,
    required this.storeName,
    required this.dealTitle,
    required this.validity,
    required this.status,
    required this.storeColor,
    required this.storeInitials,
    required this.onTap,
  });

  bool get isActive => status == 'active';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipPath(
          clipper: TicketClipper(),
          child: Container(
            color: isActive ? Colors.white : const Color(0xFFF2F2F7),
            child: Row(
              children: [
                // Stub Section (Left)
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: isActive ? storeColor.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                        style: BorderStyle.none, // Handled by CustomPaint if needed, or simple container
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isActive ? storeColor : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            storeInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dashed Line
                CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: DashedLinePainter(
                    color: Colors.grey[300]!,
                  ),
                ),

                // Body Section (Right)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          storeName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.black54 : Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dealTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.black : Colors.grey[700],
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              isActive ? Icons.access_time_rounded : Icons.history_rounded,
                              size: 14,
                              color: isActive ? storeColor : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                validity,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isActive ? Colors.black87 : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Active Indicator Strip
                if (isActive)
                  Container(
                    width: 6,
                    color: storeColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    
    // Top Right Corner
    path.lineTo(size.width, size.height);
    
    // Bottom Left Corner
    path.lineTo(0, size.height);
    
    path.close();

    // Cutouts
    double holeRadius = 10;
    double holePosition = 100; // Match the stub width

    Path holePath = Path();
    holePath.addOval(Rect.fromCircle(center: Offset(holePosition, 0), radius: holeRadius));
    holePath.addOval(Rect.fromCircle(center: Offset(holePosition, size.height), radius: holeRadius));
    
    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
