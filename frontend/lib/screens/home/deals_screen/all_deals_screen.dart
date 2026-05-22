import 'package:flutter/material.dart';
import 'deal_detail_screen.dart';

class AllDealsScreen extends StatefulWidget {
  const AllDealsScreen({super.key});

  @override
  State<AllDealsScreen> createState() => _AllDealsScreenState();
}

class _AllDealsScreenState extends State<AllDealsScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Dining', 'Lifestyle', 'Shopping'];

  final List<Deal> _allDeals = [
    Deal(
      id: 1,
      category: 'OCEAN BASKET',
      categoryIcon: Icons.restaurant,
      categoryColor: const Color(0xFFEE5F17),
      title: '15% Off Total Bill',
      xpCost: 500,
      imageUrl: 'assets/ob.png',
    ),
    Deal(
      id: 2,
      category: 'MUGG & BEAN',
      categoryIcon: Icons.coffee,
      categoryColor: const Color(0xFF3F9EB2),
      title: 'Buy 1 Get 1 Free',
      xpCost: 250,
      imageUrl: 'assets/mugg&bean.jpeg',
    ),
    Deal(
      id: 3,
      category: 'GALAXY',
      categoryIcon: Icons.shopping_bag,
      categoryColor: const Color(0xFFFF2D55),
      title: 'Rs 500 Discount',
      xpCost: 1200,
      imageUrl: 'assets/galaxy.jpg',
    ),
    Deal(
      id: 4,
      category: 'mCine',
      categoryIcon: Icons.movie,
      categoryColor: const Color(0xFF5222D0),
      title: 'Free Popcorn',
      xpCost: 300,
      imageUrl: 'assets/mcine.jpg',
    ),
    Deal(
      id: 5,
      category: 'KAIRALI SPA',
      categoryIcon: Icons.spa,
      categoryColor: const Color(0xFF3F9EB2),
      title: '20% Off Massage',
      xpCost: 800,
      imageUrl: 'assets/spa.jpg',
    ),
    Deal(
      id: 6,
      category: 'TOTAL',
      categoryIcon: Icons.local_gas_station,
      categoryColor: const Color(0xFFFF0000),
      title: 'Rs 100 Voucher',
      xpCost: 450,
      imageUrl: 'assets/total.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF0F0F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Deals',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.408,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for partners, or deals...',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0x99FFFFFF) : const Color(0x99000000),
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? const Color(0x99FFFFFF) : const Color(0x99000000),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1B1D33) : const Color(0x96FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0x2B000000),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0x2B000000),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Category filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Row(
                  children: _categories
                      .map((category) => _buildCategoryButton(category))
                      .toList(),
                ),
              ),
              const SizedBox(height: 32),
              // Deals grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exclusive Deals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xB5000000),
                            letterSpacing: -0.408,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Show sort options
                          },
                          child: Text(
                            'Sort by: Recent',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isDark ? const Color(0xFFAAB0C6) : const Color(0x8D000000),
                              letterSpacing: -0.408,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: _allDeals.length,
                      itemBuilder: (context, index) {
                        return _buildDealCard(_allDeals[index]);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF242742) : const Color(0xFFFFFFFE))
                : (isDark ? const Color(0xFF1B1D33) : Colors.white),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3F9EB2)
                  : (isDark ? const Color(0xFF2A2D4A) : const Color(0x2B000000)),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category == 'All')
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.grid_on,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF3F9EB2)
                        : (isDark ? const Color(0xFFAAB0C6) : const Color(0x80000000)),
                  ),
                ),
              if (category == 'Dining')
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.restaurant,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF3F9EB2)
                        : (isDark ? const Color(0xFFAAB0C6) : const Color(0x80000000)),
                  ),
                ),
              if (category == 'Lifestyle')
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF3F9EB2)
                        : (isDark ? const Color(0xFFAAB0C6) : const Color(0x80000000)),
                  ),
                ),
              if (category == 'Shopping')
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF3F9EB2)
                        : (isDark ? const Color(0xFFAAB0C6) : const Color(0x80000000)),
                  ),
                ),
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF3F9EB2)
                      : (isDark ? const Color(0xFFAAB0C6) : const Color(0x80000000)),
                  letterSpacing: -0.408,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(Deal deal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DealDetailScreen(
              dealImage: deal.imageUrl,
              dealCategory: deal.category,
              dealTitle: deal.title,
              dealStore: deal.category,
              discount: _extractDiscount(deal.title),
              xpCost: deal.xpCost,
              location: 'Islandwide',
              validity: 'Valid for 30 days',
              description:
                  'Enjoy exclusive benefits with this special deal. Use this offer at participating locations.',
              validationPoints: const [
                'Valid at all locations',
                'No minimum purchase required',
                'Cannot be combined with other offers',
              ],
              redeemSteps: const [
                'Tap "Claim for XP" to redeem',
                'Show your unique code at the store',
                'Enjoy your exclusive benefits!',
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1D33) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 118,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.asset(
                  deal.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: deal.categoryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          deal.categoryIcon,
                          size: 16,
                          color: deal.categoryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deal.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFAAB0C6)
                                : Colors.black.withValues(alpha: 0.55),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    deal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.408,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // XP cost and button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${deal.xpCost} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3F9EB2),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DealDetailScreen(
                                dealImage: deal.imageUrl,
                                dealCategory: deal.category,
                                dealTitle: deal.title,
                                dealStore: deal.category,
                                discount: _extractDiscount(deal.title),
                                xpCost: deal.xpCost,
                                location: 'Islandwide',
                                validity: 'Valid for 30 days',
                                description:
                                    'Enjoy exclusive benefits with this special deal. Use this offer at participating locations.',
                                validationPoints: const [
                                  'Valid at all locations',
                                  'No minimum purchase required',
                                  'Cannot be combined with other offers',
                                ],
                                redeemSteps: const [
                                  'Tap "Claim for XP" to redeem',
                                  'Show your unique code at the store',
                                  'Enjoy your exclusive benefits!',
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2D4A) : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDiscount(String title) {
    if (title.contains('%')) {
      final match = RegExp(r'(\d+%?)').firstMatch(title);
      if (match != null) {
        return match.group(1) ?? '15%';
      }
    }
    return '15%';
  }
}

class Deal {
  final int id;
  final String category;
  final IconData categoryIcon;
  final Color categoryColor;
  final String title;
  final int xpCost;
  final String imageUrl;

  Deal({
    required this.id,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.title,
    required this.xpCost,
    required this.imageUrl,
  });
}
