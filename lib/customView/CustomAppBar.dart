import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:food_app/bindings/app_binding.dart';
import 'package:get/get.dart';

import '../utils/my_application.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _CustomAppBarState extends State<CustomAppBar> {
  TextEditingController searchControllerTodo = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  @override
  void dispose() {
    searchControllerTodo.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
                onTap: (){
                  Scaffold.of(context).openDrawer();
                },
                child:  Icon(Icons.menu,color: Colors.black,)
              //SvgPicture.asset('assets/images/drawer.svg'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchControllerTodo,
                        focusNode: searchFocusNode, // Add focusNode
                        autofocus: false, // Explicitly disable autofocus
                        enableInteractiveSelection: false, // Prevent text selection
                        decoration: InputDecoration(
                          hintText: 'search_item'.tr,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onTap: () {
                          // Only focus when user explicitly taps
                          searchFocusNode.requestFocus();
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            app.appController.filterSearchResultsTodo(value);
                          }
                          // Unfocus after search
                          searchFocusNode.unfocus();
                        },
                        onEditingComplete: () {
                          // Unfocus when editing is complete
                          searchFocusNode.unfocus();
                        },
                      ),
                    ),

                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            /*  GestureDetector(
              onTap: () {
                // Open language selection
              },
              child: Row(
                children: [
                  //Image.asset('assets/flags/germany.png', width: 24, height: 24), // Add your flag image
                  const SizedBox(width: 4),
                  const Text("GER",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}