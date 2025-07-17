import 'package:flutter/material.dart';

class ItemBottomBar extends StatelessWidget {
  final String icon;          // asset path
  final String name;          // tab label
  final bool selected;        // highlight when active
  final bool showBadge;       // toggle badge on/off
  final int  badgeValue;      // value to show in badge
  final VoidCallback onPressed;

  const ItemBottomBar({
    super.key,
    required this.icon,
    required this.name,
    required this.onPressed,
    this.selected   = false,
    this.showBadge  = false,
    this.badgeValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Core icon + label
    final Widget _tabContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          icon,
          width: 22,
          height: 22,
          color: selected ? Colors.green : Colors.black,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: selected ? Colors.green : Colors.black,
          ),
        ),
      ],
    );

    // Wrap in InkWell for ripple + tap
    return InkWell(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,   // let the badge overflow
        children: [
          _tabContent,
          if (showBadge && badgeValue > 0)
            Positioned(
              // Adjust these values to fine‑tune the badge position
              top: -6,
              right: -10,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$badgeValue',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
