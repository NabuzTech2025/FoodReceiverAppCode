import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/api/Socket/socket_service.dart';
import 'package:food_app/models/today_report.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../models/DailySalesReport.dart';
import '../utils/log_util.dart';
import '../utils/my_application.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {

  late SharedPreferences sharedPreferences;
  String? bearerKey;
  List<DailySalesReport> reportList = [];
  DailySalesReport reportsss = DailySalesReport();
  DailySalesReport? _selectedReport;
  DailySalesReport? _currentDateReport;
  DateTime? _selectedDate;

  late int displayedMonth;
  late int displayedYear;
  String dateSeleted = '', salesDelivery = '0', totalSales = '0', totalOrder = '0',
      totalTax = '0', cashTotal = '0', online = '0', net = '0', discount = '0',
      deliveryFee = '0', cashMethod = '0', delivery = '0', pickUp = '0',
      dineIn = '0', pending = '0', accepted = '0', declined = '0',
      tax19 = '0', tax7 = '0';
  bool showCalendar = false;

  late AnimationController _controller;
  late Animation<double> _animation;
  // Live data indicators
  bool _isLiveDataActive = false;
  DateTime? _lastUpdateTime;
  Timer? _liveDataTimer;
  @override
  void initState() {
    super.initState();
    // Initialize displayedMonth and displayedYear to current month/year
    final now = DateTime.now();
    displayedMonth = now.month;
    displayedYear = now.year;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
    ever(app.appController.reportRefreshTrigger, (_) {
      print("ReportScreen: Refresh triggered!");
      _refreshReportData();
    });

    initVar();

    _startLiveDataUpdates();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);

    print("Bearer Key: $bearerKey"); // Debug print

    await getReports(bearerKey);

    getCurrentDateReport();

    await getLiveSaleReport();
  }

  void getCurrentDateReport() {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    print("🔍 Looking for current date report:");
    print("Today's date string: $todayString");
    print("Report list length: ${reportList.length}");

    // Debug: Print all report dates
    for (int i = 0; i < reportList.length; i++) {
      var report = reportList[i];
      print("Report $i - startDate: ${report.startDate}");
      if (report.startDate != null) {
        try {
          final reportDate = DateTime.parse(report.startDate!);
          final reportDateString = DateFormat('yyyy-MM-dd').format(reportDate);
          print("  Parsed date string: $reportDateString");
          print("  Matches today: ${reportDateString == todayString}");
        } catch (e) {
          print("  Date parsing error: $e");
        }
      }
    }

    // Find report for today's date
    DailySalesReport? foundReport;
    for (var report in reportList) {
      if (report.startDate != null) {
        try {
          final reportDate = DateTime.parse(report.startDate!);
          final reportDateString = DateFormat('yyyy-MM-dd').format(reportDate);
          if (reportDateString == todayString) {
            foundReport = report;
            print("✅ Found current date report!");
            break;
          }
        } catch (e) {
          print("❌ Error parsing date ${report.startDate}: $e");
          continue;
        }
      }
    }

    if (foundReport != null) {
      setState(() {
        _currentDateReport = foundReport;
        reportsss = foundReport!; // Set as default report to show
      });
      print("✅ Current date report set successfully");
      print("Total Sales: ${foundReport.totalSales}");
      print("Total Orders: ${foundReport.totalOrders}");
    } else {
      print("❌ No report found for today's date: $todayString");

      // Create a default report for today if none exists
      final defaultReport = DailySalesReport(
        startDate: todayString,
        totalSales: 0.0,
        totalOrders: 0,
        cashTotal: 0.0,
        onlineTotal: 0.0,
        totalTax: 0.0,
        data: null, // Will be populated by socket updates
      );

      setState(() {
        _currentDateReport = defaultReport;
        reportsss = defaultReport;
        // Optionally add to reportList
        reportList.insert(0, defaultReport);
      });

      print("🆕 Created default report for today");
    }
  }

  void _startLiveDataUpdates() {
    _liveDataTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!showCalendar) { // Only update when showing today's data
        getLiveSaleReport();
      }
    });
  }

  Future<void> getReports(String? bearerKey) async {
    try {
      print("DataBearerKEy " + bearerKey!);
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );
      final result = await ApiRepo().reportGetApi(bearerKey!);
      Get.back();
      if (result != null) {
        setState(() {
          reportList = result;
          print("reportList " + reportList.length.toString());
        });
      } else {
        showSnackbar("Error", " error");
      }
    } catch (e) {
      Get.back();
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }
  void _resetCalendarToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      showCalendar = false;
      displayedMonth = now.month;
      displayedYear = now.year;
      _selectedReport = null;
      _selectedDate = null;
      dateSeleted = '';
    });
    print("📅 Calendar reset to current month: ${displayedMonth}/${displayedYear}");
  }

  Future<void> getLiveSaleReport() async {
    try {
      print("🔄 Starting getLiveSaleReport...");

      if (bearerKey == null || bearerKey!.isEmpty) {
        print("❌ Bearer token is null or empty");
        _setEmptyValues();
        return;
      }

      print("✅ Bearer token available: ${bearerKey!.substring(0, 20)}...");

      // Call the API
      GetTodayReport model = await CallService().getLiveSaleData();

      print("✅ API call completed successfully");
      print("📊 Model Data - totalSales: ${model.totalSales}, totalOrders: ${model.totalOrders}");

      // Check if model has error code
      if (model.code != null && model.code != 200) {
        print("⚠️ API returned code: ${model.code}, message: ${model.mess}");
        _setEmptyValues();
        return;
      }

      // ✅ Update state with received data (even if it's all zeros)
      setState(() {
        totalSales = '€${formatAmount(model.totalSales ?? 0.0)}';
        totalOrder = '${model.totalOrders ?? 0}';
        totalTax = '€${formatAmount(model.totalTax ?? 0.0)}';
        cashTotal = '€${formatAmount(model.cashTotal ?? 0.0)}';

        // Handle onlineTotal
        double onlineValue = 0.0;
        if (model.onlineTotal != null) {
          onlineValue = model.onlineTotal is int
              ? (model.onlineTotal as int).toDouble()
              : model.onlineTotal as double;
        }
        online = '€${formatAmount(onlineValue)}';

        net = '€${formatAmount(model.netTotal ?? 0.0)}';

        // Handle discountTotal
        int discountValue = 0;
        if (model.discountTotal != null) {
          discountValue = model.discountTotal is double
              ? (model.discountTotal as double).toInt()
              : model.discountTotal as int;
        }
        discount = '$discountValue';

        // Handle deliveryTotal
        double deliveryValue = 0.0;
        if (model.deliveryTotal != null) {
          deliveryValue = model.deliveryTotal is int
              ? (model.deliveryTotal as int).toDouble()
              : model.deliveryTotal as double;
        }
        deliveryFee = '€${formatAmount(deliveryValue)}';

        salesDelivery = '€${formatAmount(model.totalSalesDelivery ?? 0.0)}';
        cashMethod = '${model.paymentMethods?.cash ?? 0}';
        delivery = '${model.orderTypes?.delivery ?? 0}';
        pickUp = '${model.orderTypes?.pickup ?? 0}';
        dineIn = '${model.orderTypes?.dineIn ?? 0}';
        pending = '${model.approvalStatuses?.pending ?? 0}';
        accepted = '${model.approvalStatuses?.accepted ?? 0}';
        declined = '${model.approvalStatuses?.declined ?? 0}';
        tax19 = '€${formatAmount(model.taxBreakdown?.d19 ?? 0.0)}';
        tax7 = '€${formatAmount(model.taxBreakdown?.d7 ?? 0.0)}';

        // Set live data as active even for empty data
        _isLiveDataActive = true;
        _lastUpdateTime = DateTime.now();
      });

      print('✅ State updated successfully');
      print('📊 UI Variables - totalSales: $totalSales, totalOrder: $totalOrder');

      // ✅ Show user-friendly message if all values are zero
      bool hasData = (model.totalSales ?? 0) > 0 || (model.totalOrders ?? 0) > 0;
      if (!hasData) {
        print("ℹ️ No sales data available for today yet");
        // Optionally show a subtle indicator in UI
      }

    } catch (e, stackTrace) {
      print('❌ Error in getLiveSaleReport: $e');
      print('📋 Stack trace: $stackTrace');

      // ✅ Set empty values instead of crashing
      _setEmptyValues();

      // ✅ Don't show error to user for 204 responses
      if (!e.toString().contains('204')) {
        // Only show actual errors, not "no data" scenarios
        showSnackbar("Info", "Unable to load live sales data");
      }
    }
  }
  void _setEmptyValues() {
    setState(() {
      _isLiveDataActive = false;

      totalSales = '€0.00';
      totalOrder = '0';
      totalTax = '€0.00';
      cashTotal = '€0.00';
      online = '€0.00';
      net = '€0.00';
      discount = '0';
      deliveryFee = '€0.00';
      salesDelivery = '€0.00';
      cashMethod = '0';
      delivery = '0';
      pickUp = '0';
      dineIn = '0';
      pending = '0';
      accepted = '0';
      declined = '0';
      tax19 = '€0.00';
      tax7 = '€0.00';
    });

    print("📊 Set empty/default values for UI");
  }

  Future<void> _refreshReportData() async {
    print("🔄 Refreshing report data...");

    try {
      // ✅ Add this line at the beginning
      _resetCalendarToCurrentMonth();

      await getReports(bearerKey);
      getCurrentDateReport();
      await getLiveSaleReport();

      print("✅ Report data refresh completed");
    } catch (e) {
      print("❌ Error refreshing report data: $e");
    }
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(15),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (showCalendar) {
                      setState(() {
                        showCalendar = false;
                        _selectedReport = null;
                        _selectedDate = null; // Reset selected date
                        dateSeleted = '';
                        _resetCalendarToCurrentMonth();
                      });
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 100,
                            color: Colors.transparent,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Center(
                                  child: Text(
                                    'Live Sale',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: "Mulish",
                                        color: Color(0xff0C831F),
                                        height: 0),
                                  ),
                                ),
                                Positioned(
                                  right: -8,
                                  top: 0,
                                  child: FadeTransition(
                                      opacity: _animation,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: Color(0xff0C831F),
                                          shape: BoxShape.circle,
                                        ),
                                      )),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        dateSeleted.isEmpty
                            ? DateFormat('MMMM y').format(DateTime.now())
                            : dateSeleted,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff757B8F),
                            fontWeight: FontWeight.w600,
                            height: 0,
                            fontFamily: "Mulish"),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showCalendar = !showCalendar; // Toggle calendar visibility
                      if (!showCalendar) {
                        _selectedReport = null;
                        _selectedDate = null; // Reset selected date
                        dateSeleted = '';
                        _resetCalendarToCurrentMonth();
                      }
                    });
                  },
                  child: Row(
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                            fontFamily: "Mulish",
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xff1F1E1E)),
                      ),
                      SizedBox(width: 5),
                      SvgPicture.asset(
                        'assets/images/dropdown.svg',
                        height: 5,
                        width: 11,
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Show calendar if showCalendar is true
            if (showCalendar) ...[
              _calendar(),
              const SizedBox(height: 16),
            ],

            showCalendar
                ? _historyStatus(_selectedReport ?? _currentDateReport ?? reportsss)
                : _todayStatus(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(displayedYear, displayedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: "Select Month",
      fieldHintText: "Month/Year",
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (selected != null) {
      setState(() {
        displayedMonth = selected.month;
        displayedYear = selected.year;
        dateSeleted = DateFormat('MMMM y').format(selected);
        _selectedReport = null;
        _selectedDate = null; // Reset selected date
      });
    }
  }

  Map<int, DailySalesReport> _getReportsForMonth(int month, int year) {
    final Map<int, DailySalesReport> map = {};

    for (var report in reportList) {
      if (report.startDate != null) {
        final date = DateTime.parse(report.startDate!);
        if (date.month == month && date.year == year) {
          map[date.day] = report;
        }
      }
    }
    return map;
  }

  Widget _calendar() {
    final reportMap = _getReportsForMonth(displayedMonth, displayedYear);

    final firstDay = DateTime(displayedYear, displayedMonth, 1);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final totalDays = DateTime(displayedYear, displayedMonth + 1, 0).day;

    final prevMonth = displayedMonth == 1 ? 12 : displayedMonth - 1;
    final prevYear = displayedMonth == 1 ? displayedYear - 1 : displayedYear;
    final prevMonthDays = DateTime(displayedYear, displayedMonth, 0).day;

    final nextMonth = displayedMonth == 12 ? 1 : displayedMonth + 1;
    final nextYear = displayedMonth == 12 ? displayedYear + 1 : displayedYear;

    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7; // Full weeks

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  // Move to previous month
                  displayedMonth = prevMonth;
                  displayedYear = prevYear;
                  _selectedReport = null; // reset selected report when month changes
                });
              },
            ),
            Text(
              "${_monthName(displayedMonth)} $displayedYear",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  // Move to next month
                  displayedMonth = nextMonth;
                  displayedYear = nextYear;
                  _selectedReport =
                      null; // reset selected report when month changes
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          children: [
            _buildWeekdayRow(),
            ...List.generate(totalCells ~/ 7, (week) {
              return TableRow(
                children: List.generate(7, (dayIndex) {
                  final cellIndex = week * 7 + dayIndex;
                  DateTime cellDate;

                  if (cellIndex < startWeekday) {
                    // Leading days from previous month
                    final day = prevMonthDays - (startWeekday - cellIndex - 1);
                    cellDate = DateTime(prevYear, prevMonth, day);
                  } else if (cellIndex >= startWeekday + totalDays) {
                    // Trailing days from next month
                    final day = cellIndex - (startWeekday + totalDays) + 1;
                    cellDate = DateTime(nextYear, nextMonth, day);
                  } else {
                    // Current month
                    final day = cellIndex - startWeekday + 1;
                    cellDate = DateTime(displayedYear, displayedMonth, day);
                  }

                  final isCurrentMonth = cellDate.month == displayedMonth;
                  final report = isCurrentMonth ? reportMap[cellDate.day] : null;

                  return _calendarCellWithDate(
                      cellDate, report, isCurrentMonth);
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  Widget _calendarCellWithDate(DateTime date, DailySalesReport? report, bool isCurrentMonth) {
    print("=== Calendar Cell Debug ===");
    print("Date: ${date.day}");
    print("Report is null: ${report == null}");

    if (report != null) {
      print("Report totalSales: ${report.totalSales}");
      print("Report data is null: ${report.data == null}");
    }

    final textColor = isCurrentMonth ? Colors.black : Colors.grey[600];
    return GestureDetector(
      onTap: () {
        if (report != null) {
          setState(() {
            _selectedReport = report;
            _selectedDate = date;
            dateSeleted = DateFormat('MMMM y').format(date);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.white,
        child: SizedBox(
          height: 65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${date.day}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              if (report != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/ic_report.svg',
                      height: 12,
                      width: 12,
                    ),
                    const SizedBox(height: 2),
                    Text("€${formatAmount(report.totalSales ?? 0)}",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                      ),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
  TableRow _buildWeekdayRow() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return TableRow(
      children: days.map((day) {
        return Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _historyStatus(DailySalesReport? report) {
    if (report == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text( _selectedDate != null
              ? DateFormat('dd MMMM y').format(_selectedDate!)
              : "Sales Report",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("No data available."),
        ],
      );
    }

    final approval = report.data?.approvalStatuses ?? {};
    final cashTotal = report.cashTotal ?? 0.0;
    final onlineTotal = report.onlineTotal ?? 0.0;
    final totalSales = report.totalSales ?? 0.0;
    final order = report.totalOrders ?? 0.0;
    final tax = report.totalTax ?? 0.0;
    final net = report.data?.netTotal ?? 0.0;
    final discount = report.data?.discountTotal ?? 0.0;
    final delivery = report.data?.deliveryTotal ?? 0.0;
    final salesDelivery = report.data?.totalSalesDelivery ?? 0.0;
    final payment = report.data?.paymentMethods ?? {};
    final orderType = report.data?.orderTypes ?? {};
    final taxBreakdown = report.data?.taxBreakdown ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
              children: [
                Lottie.asset(
                    'assets/animations/sales.json',
                    width: 30,
                    height: 30,
                    repeat: true, ),
                Text( _selectedDate != null
                    ?  DateFormat('dd MMMM y').format(_selectedDate!)
                    : "Sales Report",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),

        if (_isLiveDataActive && _selectedReport == null && _lastUpdateTime != null) ...[
          const SizedBox(height: 4),
          Text(
            "Last updated: ${DateFormat('HH:mm:ss').format(_lastUpdateTime!)}",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total Sales  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "€${formatAmount(totalSales)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total Order  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:"${order.toInt().toString()}", // Convert to int for display
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total tax ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "€${formatAmount(tax)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Cash Total  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "€${formatAmount(cashTotal)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Online ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "€${formatAmount(onlineTotal)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Net (Subtotal) ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "€${formatAmount(net)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Discounts  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${discount.toInt().toString()}", // Keep as int for display
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Delivery Fees  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "€${formatAmount(delivery)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total Sales(+ Delivery Fees)  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "€${formatAmount(salesDelivery)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/payment.json',
              width: 30,
              height: 30,
              repeat: true, ),
            Text("Payment Methods",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Cash : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${payment['cash'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/orderType.json',
              width: 30,
              height: 30,
              repeat: true, ),
            Text("Order Types",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Delivery : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${orderType['delivery'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Pickup : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${orderType['pickup'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Dine In : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${orderType['dine_in'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/approval.json',
              width: 30,
              height: 30,
              repeat: true, ),
            const Text("Approval Status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Pending: ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${approval['pending'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Accepted : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${approval['accepted'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Declined : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: "${approval['declined'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/tax.json',
              width: 30,
              height: 30,
              repeat: true, ),
            const Text("Tax Breakdown",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "19: ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:"${taxBreakdown ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "7: ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:"${taxBreakdown ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
  Widget _todayStatus() {
    print("=== _todayStatus Debug ===");
    print("totalSales: '$totalSales'");
    print("totalOrder: '$totalOrder'");
    print("showCalendar: $showCalendar");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
              children: [
                Lottie.asset(
                    'assets/animations/sales.json',
                    width: 30,
                    height: 30,
                    repeat: true, ),
                Text( _selectedDate != null
                    ?  DateFormat('dd MMMM y').format(_selectedDate!)
                    : "Sales Report",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),

        if (_isLiveDataActive && _selectedReport == null && _lastUpdateTime != null) ...[
          const SizedBox(height: 4),
          Text(
            "Last updated: ${DateFormat('HH:mm:ss').format(_lastUpdateTime!)}",
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total Sales  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: totalSales,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total Order  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:totalOrder, // Convert to int for display
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total tax ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: totalTax,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Cash Total  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: cashTotal,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Online ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: online,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Net (Subtotal) ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: net,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Discounts  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: discount, // Keep as int for display
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Delivery Fees  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: deliveryFee,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Total Sales(+ Delivery Fees)  ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: salesDelivery,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/payment.json',
              width: 30,
              height: 30,
              repeat: true, ),
            Text("Payment Methods",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Cash : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:cashMethod,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/orderType.json',
              width: 30,
              height: 30,
              repeat: true, ),
            Text("Order Types",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Delivery : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: delivery,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Pickup : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: pickUp,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Dine In : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:dineIn,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/approval.json',
              width: 30,
              height: 30,
              repeat: true, ),
            const Text("Approval Status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Pending: ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: pending,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Accepted : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: accepted,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "Declined : ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: declined,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Lottie.asset(
              'assets/animations/tax.json',
              width: 30,
              height: 30,
              repeat: true, ),
            const Text("Tax Breakdown",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "19: ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:tax19,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "7: ",
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text:tax7,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  void showCalendarDialog(BuildContext context, DailySalesReport report) {
    final DateTime parsedDate = DateTime.parse(report.startDate!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Report for ${_formatDate(parsedDate)}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Sales: €${report.totalSales}"),
            Text("Orders: ${report.totalOrders}"),
            Text("Cash: €${report.cashTotal}"),
            Text("Online: €${report.onlineTotal}"),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}