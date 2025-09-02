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
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    searchControllerTodo.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    searchFocusNode.unfocus();
    searchControllerTodo.removeListener(_onSearchTextChanged);
    searchControllerTodo.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final searchText = searchControllerTodo.text;
    print("🔍 Search text changed: '$searchText'");

    setState(() {
      _showClearButton = searchText.isNotEmpty;
    });

    if (app.appController.selectedTabIndex == 0) {
      app.appController.filterSearchResultsTodo(searchText);
    } else if (app.appController.selectedTabIndex == 1) {
      app.appController.filterSearchResultsReservation(searchText);
    }
  }

  void _activateSearch() {
    setState(() {
      _isSearchActive = true;
    });
    // Small delay to ensure widget is built before requesting focus
    Future.delayed(Duration(milliseconds: 50), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(searchFocusNode);
      }
    });
  }

  void _deactivateSearch() {
    setState(() {
      _isSearchActive = false;
    });
    searchFocusNode.unfocus();
  }

  void _handleSearchTap() {
    if (!searchFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(searchFocusNode);
    }
  }
  Widget _buildSearchBox() {
    if (!_isSearchActive) {
      // ✅ Inactive state - Show container that looks like TextField
      return GestureDetector(
        onTap: _activateSearch,
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    searchControllerTodo.text.isEmpty
                        ? 'search_item'.tr
                        : searchControllerTodo.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: searchControllerTodo.text.isEmpty
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                  ),
                ),
              ),
              if (searchControllerTodo.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    searchControllerTodo.clear();
                    if (app.appController.selectedTabIndex == 0) {
                      app.appController.clearSearch();
                    } else if (app.appController.selectedTabIndex == 1) {
                      app.appController.clearReservationSearch();
                    }
                  },
                  child: Icon(Icons.clear, color: Colors.grey, size: 18),
                ),
            ],
          ),
        ),
      );
    } else {
      // ✅ Active state - Show actual TextField
      return Container(
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
                style: TextStyle(fontSize: 14),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'search_item'.tr,
                  hintStyle: TextStyle(fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
                onSubmitted: (value) {
                  if (app.appController.selectedTabIndex == 0) {
                    app.appController.filterSearchResultsTodo(value);
                  } else if (app.appController.selectedTabIndex == 1) {
                    app.appController.filterSearchResultsReservation(value);
                  }
                  _deactivateSearch();
                },
                onEditingComplete: () {
                  _deactivateSearch();
                },
              ),
            ),
            if (_showClearButton)
              GestureDetector(
                onTap: () {
                  searchControllerTodo.clear();
                  if (app.appController.selectedTabIndex == 0) {
                    app.appController.clearSearch();
                  } else if (app.appController.selectedTabIndex == 1) {
                    app.appController.clearReservationSearch();
                  }
                },
                child: Icon(Icons.clear, color: Colors.grey, size: 18),
              ),
            // ✅ Done button to close search
            SizedBox(width: 8),
            GestureDetector(
              onTap: _deactivateSearch,
              child: Icon(Icons.keyboard_hide, color: Colors.grey, size: 18),
            ),
          ],
        ),
      );
    }
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
            Obx(() {
              if (app.appController.selectedTabIndex == 0 || app.appController.selectedTabIndex == 1){
                return Expanded(
                  child: _buildSearchBox()
                ) ;
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