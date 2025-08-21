import 'package:flutter/material.dart';
import 'package:food_app/ui/Tax%20MAnagement/tax_bottomsheet.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_added_tax_response_model.dart';

class Taxmanagement extends StatefulWidget {
  const Taxmanagement({super.key});

  @override
  State<Taxmanagement> createState() => _TaxmanagementState();
}

class _TaxmanagementState extends State<Taxmanagement> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  List<getAddedtaxResponseModel> storeTaxesList = [];

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getStoreTaxes();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(12),
        child:Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('manage'.tr, style: TextStyle(
                    fontFamily: 'Mulish', fontSize: 18, fontWeight: FontWeight.bold
                )),
                GestureDetector(
                  onTap: () {
                    showTaxManagementBottomSheet(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: const Color(0xFFFCAE03),
                    ),
                    child: const Center(
                      child: Text('Add New', style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'Mulish',
                      )),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFFECF8FF),
              ),
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax Name',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Mulish'
                          ),
                        ),
                        Text('Percentage',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'Mulish'
                            )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    child: Center(
                      child: Text('Action',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            fontFamily: 'Mulish'
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // Dynamic list of taxes
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(20),
                child: const Center(),
              )
            else if (storeTaxesList.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'No taxes found',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Mulish',
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: storeTaxesList.length,
                itemBuilder: (context, index) {
                  final tax = storeTaxesList[index];
                  var taxid=tax.id.toString();
                  print('taxidis$taxid');
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.25,
                                  child: Text(
                                    tax.name ?? 'Unknown Tax',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        fontFamily: 'Mulish'
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.2,
                                  child: Center(
                                    child: Text(
                                      '${tax.percentage?.toStringAsFixed(1) ?? '0'}%',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          fontFamily: 'Mulish'
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Edit button
                          GestureDetector(
                            onTap: () {
                              print('Delete button click - Tax ID: ${tax.id}');
                              print('Tax object details: Name=${tax.name}, Percentage=${tax.percentage}');

                              if (tax.id != null) {
                                print('Passing taxId to confirmation dialog: ${tax.id}');
                                _showDeleteTaxConfirmation(context, tax.name ?? 'Tax', tax.id!);
                              } else {
                                print('Tax ID is null!');
                                Get.snackbar('Error', 'Invalid tax ID');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xff0C831F)
                              ),
                              child: const Center(
                                child: Icon(
                                    Icons.mode_edit_outline_outlined,
                                    color: Colors.white,
                                    size: 16
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          GestureDetector(
                            onTap: () {
                              if (tax.id != null) {
                                _showDeleteTaxConfirmation(context, tax.name ?? 'Tax', tax.id!);
                              } else {
                                Get.snackbar('Error', 'Invalid tax ID');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xffE25454)
                              ),
                              child: const Center(
                                child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 16
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        )
        ),
      ),
    );
  }
  void showTaxManagementBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaxBottomSheet(
          onDataAdded: () async {
            await getStoreTaxes(showLoader: false);
          },)
      ),
    );
  }

  Future<void> getStoreTaxes({bool showLoader = true}) async {
    if (sharedPreferences == null) {
      print('SharedPreferences not initialized yet');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (showLoader) {
      setState(() {
        isLoading = true;
      });
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )
        ),
        barrierDismissible: false,
      );
    }

    try {

      List<getAddedtaxResponseModel> storeTax = await CallService().getStoreTax(storeId!);

      if (showLoader) {
        Get.back();
      }

      setState(() {
        storeTaxesList=storeTax;
        isLoading = false;
      });

    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Store taxes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
// Add this method to your _Tax managementState class

  // void _showDeleteTaxConfirmation(BuildContext context, String taxName, int taxId) {
  //   print('Confirmation dialog me ayi taxId: $taxId');
  //   print('Tax name: $taxName');
  //
  //   Get.dialog(
  //     AlertDialog(
  //       title: const Text('Delete Tax'),
  //       content: Text('Are you sure you want to delete "$taxName"?\nTax ID: $taxId'), // ID show karo dialog me
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             print('Delete confirm kiya, taxId pass kar rahe: $taxId');
  //             Get.back();
  //             _deleteTax(taxId);
  //           },
  //           child: const Text('Delete', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  void _showDeleteTaxConfirmation(BuildContext context, String taxName, int taxId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                // margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20,),
                    Text(
                      'Are you sure you want to delete "$taxName"?',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          fontFamily: 'Mulish'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 35,
                          width: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E9AAF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),
                        Container(
                          height: 35,
                          width: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE25454),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Get.back();
                              _deleteTax(taxId);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: -20,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFED4C5C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),)
            ]
        ),
      ),
    );
  }

  Future<void> _deleteTax(int taxId) async {
    // Yahan taxId print karke check karo
    print('Delete method me ayi taxId: $taxId');
    print('TaxId type: ${taxId.runtimeType}');

    setState(() {
      isLoading = true;
    });

    Get.dialog(
      Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          )
      ),
      barrierDismissible: false,
    );

    try {

      print('API call kar rahe hain taxId: $taxId ke liye');

      await CallService().deleteStoreTax(taxId);

      Get.back();
      Get.snackbar('Success', 'Tax deleted successfully');

      await getStoreTaxes(showLoader: false);

    } catch (e) {
      Get.back();
      print('Error deleting tax: $e');
      Get.snackbar('Error', 'Failed to delete tax');
      setState(() {
        isLoading = false;
      });
    }
  }

  void showEditTaxBottomSheet(BuildContext context, getAddedtaxResponseModel tax) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaxBottomSheet(
          onDataAdded: () async {
            await getStoreTaxes(showLoader: false);
          },
          editTaxName: tax.name,
          editTaxPercentage: tax.percentage?.toString(),
          editTaxId: tax.id,
          isEditMode: true,
        ),
      ),
    );
  }
}
