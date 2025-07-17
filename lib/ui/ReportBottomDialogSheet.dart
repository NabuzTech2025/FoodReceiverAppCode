
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/DailySalesReport.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportScreenBottom extends StatefulWidget {
  @override
  _ReportScreenBottomState createState() => _ReportScreenBottomState();
}

class _ReportScreenBottomState extends State<ReportScreenBottom> {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  List<DailySalesReport> reportList = [];

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    initVar();
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    getReports(bearerKey);
  }

  Future<void> getReports(String? bearerKey) async {
    try {
      print("DataBearerKey $bearerKey");
      Get.dialog(
        const Center(
            child: CupertinoActivityIndicator(
              radius: 20,
              color: Colors.orange,
            )),
        barrierDismissible: false,
      );
      final result = await ApiRepo().reportGetApi(bearerKey!);
      Get.back();
      if (result != null) {
        setState(() {
          reportList = result;
        });
      } else {
        showSnackbar("Error", "Error fetching reports.");
      }
    } catch (e) {
      Get.back();
      Log.loga(title, "Report API Error: $e");
      showSnackbar("API Error", "An error occurred: $e");
    }
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _calendar(),
          ],
        ),
      ),
    );
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
    final year = selectedYear;
    final month = selectedMonth;

    final firstDay = DateTime(year, month, 1);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = DateTime(year, month + 1, 0).day;

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevMonthDays = DateTime(year, month, 0).day;

    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;

    final reportMap = _getReportsForMonth(month, year);
    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left,color: Colors.green,),
                  onPressed: () {
                    setState(() {
                      if (selectedMonth == 1) {
                        selectedMonth = 12;
                        selectedYear--;
                      } else {
                        selectedMonth--;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right,color: Colors.green,),
                  onPressed: () {
                    setState(() {
                      if (selectedMonth == 12) {
                        selectedMonth = 1;
                        selectedYear++;
                      } else {
                        selectedMonth++;
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: DateFormat('MMMM').format(DateTime(year, month)) + ', ',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: year.toString(),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                    final day = prevMonthDays - (startWeekday - cellIndex - 1);
                    cellDate = DateTime(prevYear, prevMonth, day);
                  } else if (cellIndex >= startWeekday + totalDays) {
                    final day = cellIndex - (startWeekday + totalDays) + 1;
                    cellDate = DateTime(nextYear, nextMonth, day);
                  } else {
                    final day = cellIndex - startWeekday + 1;
                    cellDate = DateTime(year, month, day);
                  }

                  final isCurrentMonth = cellDate.month == month;
                  final report = isCurrentMonth ? reportMap[cellDate.day] : null;

                  return _calendarCellWithDate(cellDate, report, isCurrentMonth);
                }),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _calendarCellWithDate(DateTime date, DailySalesReport? report, bool isCurrentMonth) {
    final textColor = isCurrentMonth ? Colors.black : Colors.grey[400];

    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${date.day}",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 2),
            if (report != null)
              GestureDetector(
                onTap: () => showCalendarDialog(
                  context,
                  report,
                  DateFormat('yyyy-MM-dd').format(date),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/ic_report_dialog.svg',
                      height: 12,
                      width: 12,
                    ),
                    const SizedBox(height: 2),
                    Text( "€${formatAmount(report.totalSales ?? 0)}",
                      //"€${report.totalSales!.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
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

  void showCalendarDialog(BuildContext context, DailySalesReport report, String day) {
    final DateTime parsedDate = DateTime.parse(report.startDate!);
    getOrdersFilter(bearerKey, true, day);
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> getOrdersFilter(String? bearerKey, bool orderType, String date) async {
    try {
      if (orderType) {
        Get.dialog(
          const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
                color: Colors.orange,
              )),
          barrierDismissible: false,
        );
      }
      final Map<String, dynamic> data = {
        "store_id": 4,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);
      if (orderType) Get.back();

      if (result.isNotEmpty && result.first.code == null) {
        setState(() {
          app.appController.setOrders(result);
          Navigator.of(context).pop(date);
        });
      } else {
        String errorMessage = result.isNotEmpty
            ? result.first.mess ?? "Unknown error"
            : "No data returned";
        showSnackbar("Error", errorMessage);
        Navigator.of(context).pop(date);
      }
    } catch (e) {
      Log.loga(title, "Order Filter Error: $e");
      showSnackbar("API Error", "An error occurred: $e");
      Navigator.of(context).pop(date);
    }
  }
}
