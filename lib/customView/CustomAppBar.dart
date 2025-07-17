import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_app/bindings/app_binding.dart';
import 'package:get/get.dart';

import '../utils/my_application.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
   CustomAppBar({super.key});

  TextEditingController searchControllerTodo = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
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
                        decoration: InputDecoration(
                          hintText: 'search_item'.tr,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            app.appController.filterSearchResultsTodo(value);
                          }
                        },
                      ),
                    ),
                   /* GestureDetector(
                      onTap: (){
                        app.appController
                            .filterSearchResultsTodo("");
                        searchControllerTodo.text = "";
                        searchControllerTodo.clear();
                      },
                      child: Icon(Icons.clear, color: Colors.green),
                    )*/
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
