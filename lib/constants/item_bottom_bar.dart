// import 'package:flutter/material.dart';
//
// class ItemBottomBar extends StatelessWidget {
//   final String icon;          // asset path
//   final String name;          // tab label
//   final bool selected;        // highlight when active
//   final bool showBadge;       // toggle badge on/off
//   final int  badgeValue;      // value to show in badge
//   final VoidCallback onPressed;
//
//   const ItemBottomBar({
//     super.key,
//     required this.icon,
//     required this.name,
//     required this.onPressed,
//     this.selected   = false,
//     this.showBadge  = false,
//     this.badgeValue = 0,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final Widget _tabContent = Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Image.asset(
//           icon,
//           width: 20,
//           height: 20,
//           color: selected ? Colors.green : Colors.black,
//         ),
//         const SizedBox(height: 4),
//         Text(
//           name,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: selected ? Colors.green : Colors.black,
//           ),
//         ),
//       ],
//     );
//     return InkWell(
//       onTap: onPressed,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           _tabContent,
//           if (showBadge && badgeValue > 0)
//             Positioned(
//               top: -6,
//               right: -10,
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
//                 decoration: const BoxDecoration(
//                   color: Colors.orange,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: Text(
//                     '$badgeValue',
//                     style: const TextStyle(
//                       fontSize: 10,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class ItemBottomBar extends StatelessWidget {
  final String icon;          // asset path
  final String name;          // tab label
  final bool selected;        // highlight when active
  final bool showBadge;       // toggle badge on/off
  final int  badgeValue;      // value to show in badge
  final VoidCallback onPressed;
  final double? iconWidth;    // customizable icon width
  final double? iconHeight;   // customizable icon height

  const ItemBottomBar({
    super.key,
    required this.icon,
    required this.name,
    required this.onPressed,
    this.selected   = false,
    this.showBadge  = false,
    this.badgeValue = 0,
    this.iconWidth  = 20,
    this.iconHeight = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(icon,
                    width: iconWidth,
                    height: iconHeight,
                    color: selected ? Colors.green : Colors.black,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.green : Colors.black,
                    ),
                  ),
                ],
              ),
              if (showBadge && badgeValue > 0)
                Positioned(
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
        ),
      ),
    );
  }
}