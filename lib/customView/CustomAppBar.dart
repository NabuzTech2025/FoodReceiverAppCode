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
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    // ✅ Real-time search listener add करें
    searchControllerTodo.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    // ✅ Listener remove करना जरूरी है memory leak से बचने के लिए
    searchControllerTodo.removeListener(_onSearchTextChanged);
    searchControllerTodo.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // ✅ Real-time search function
  void _onSearchTextChanged() {
    final searchText = searchControllerTodo.text;
    print("🔍 Search text changed: '$searchText'");

    // ✅ Update clear button visibility
    setState(() {
      _showClearButton = searchText.isNotEmpty;
    });

    // Real-time filtering
    app.appController.filterSearchResultsTodo(searchText);
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

            // Search box ko conditionally show karne ke liye Obx use karenge
            Obx(() {
              // Sirf Order screen (index 0) par search box show karenge
              if (app.appController.selectedTabIndex == 0) {
                return Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchControllerTodo,
                            focusNode: searchFocusNode,
                            autofocus: false,
                            enableInteractiveSelection: true,
                            style: TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'search_item'.tr,
                              hintStyle: TextStyle(fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () {
                              searchFocusNode.requestFocus();
                            },
                            onSubmitted: (value) {
                              app.appController.filterSearchResultsTodo(value);
                              searchFocusNode.unfocus();
                            },
                            onEditingComplete: () {
                              searchFocusNode.unfocus();
                            },
                          ),
                        ),
                        // ✅ Clear search button (simple approach)
                        if (_showClearButton)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                searchControllerTodo.clear();
                                searchFocusNode.unfocus();
                                // Clear will automatically trigger the listener
                              },
                              child: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              } else {
                // Report screen aur Settings screen par search box hide kar denge
                return Expanded(child: SizedBox.shrink());
              }
            }),

            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}