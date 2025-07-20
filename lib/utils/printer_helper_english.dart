import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:food_app/models/OrderItem.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';

class PrinterHelperEnglish {

  static Future<void> printTestFromSavedIp({required BuildContext context,
    required Order order, required String? store, required bool? auto,}) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIndex = prefs.getInt('selected_ip_index');
    if (auto == false) {
      if (selectedIndex == null) {
        _showSnackbar(context, 'no_printer_selected'.tr);
        Navigator.of(context).pop(true);
        return;
      }
    }

    final ip = prefs.getString('printer_ip_$selectedIndex');

    if (ip == null || ip.trim().isEmpty) {
      if (auto == false) {
        _showSnackbar(context, 'empty_printer_ip'.tr);
        Navigator.of(context).pop(true);
        return;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final result = await printer.connect(ip!, port: 9100);

      if (result == PosPrintResult.success) {
        await _printOrderDetails(printer, order, store);
        printer.disconnect();
        if (auto == false) {
          _showSnackbar(context, 'printer_success'.tr);
          Navigator.of(context).pop(true);
        }
      } else {
        if (auto == false) {
          _showSnackbar(context, '${'printer_failed'.tr}: $result');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (auto == false) {
        _showSnackbar(context, '${'printer_error'.tr}: $e');
        Navigator.of(context).pop(true);
      }
    }
  }
  //
  // static Future<void> _printOrderDetails(NetworkPrinter printer, Order order, String? store) async {
  //   String formatAmount(double? amount) {
  //     if (amount == null) return "0";
  //
  //     final locale = Get.locale?.languageCode ?? 'en';
  //     String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
  //     return NumberFormat('#,##0.0#', localeToUse).format(amount);
  //   }
  //
  //   final now = DateTime.now();
  //   final dateTimeStr = '${now.day}/${now.month}/${now.year},'
  //       ' ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  //
  //   var amount = (order.payment?.amount ?? 0.0).toStringAsFixed(1);
  //   var discount = (order.invoice?.discount_amount ?? 0.0).toStringAsFixed(1);
  //   var delFee = (order.invoice?.delivery_fee ?? 0.0).toStringAsFixed(1);
  //   var preSubTotal = (double.parse(amount) + double.parse(discount) - double.parse(delFee)).toStringAsFixed(1);
  //   final subtotal = preSubTotal;
  //
  //   final discountData = order.invoice?.discount_amount ?? 0.0;
  //
  //   printer.text(" ${store ?? ''}",
  //     styles: PosStyles(align: PosAlign.center, bold: true),);
  //
  //   printer.text("${'order'.tr} # ${order.id ?? ''}",
  //     styles: PosStyles(align: PosAlign.center, bold: true),
  //   );
  //
  //   printer.setStyles(PosStyles(align: PosAlign.center));
  //   printer.text(
  //     sanitizeText("${'invoice_number'.tr}: ${order.invoice?.invoiceNumber ?? ''}"),
  //     styles: PosStyles(bold: true),
  //   );
  //   printer.text(
  //     sanitizeText("${'date'.tr}: ${order.createdAt ?? dateTimeStr}"),
  //     styles: PosStyles(bold: true),
  //   );
  //   printer.hr();
  //   printer.text(
  //     sanitizeText("${'customer'.tr}: ${(order.shipping_address?.customer_name ?? '')}"),
  //     styles: PosStyles(align: PosAlign.left, bold: true),
  //   );
  //   printer.text(
  //     "${'address'.tr}: ${order.shipping_address?.line1 ?? ""}, ${order.shipping_address?.city ?? ""}",
  //     styles: PosStyles(align: PosAlign.left, bold: true),
  //   );
  //   printer.text(
  //     "${'phone'.tr}: ${order.shipping_address?.phone ?? ""}",
  //     styles: PosStyles(align: PosAlign.left, bold: true),
  //   );
  //   printer.hr();
  //   printer.feed(1);
  //
  //   _printOrderItems(printer, order);
  //   printer.hr();
  //   _printItemWithNote(
  //       printer: printer,
  //       left: "${'subtotal'.tr}:",
  //       right: subtotal, note: '');
  //
  //   if (discountData != 0.0) {
  //     _printItemWithNote(
  //         printer: printer,
  //         left: "${'discount'.tr}:",
  //         right: discount,
  //         note: '');
  //   }
  //
  //   if (delFee != 0.0)
  //   //if (delFee != "0.0")
  //   {
  //     _printItemWithNote(
  //         printer: printer,
  //         left: "${'delivery_fee'.tr}:",
  //         right: delFee,
  //         note: '');
  //   }
  //
  //   printer.hr();
  //   _printItemWithNote(
  //     printer: printer,
  //     left: "${'grand_total'.tr}:",
  //     right:"${formatAmount(order.invoice?.totalAmount??00)}",
  //    // right: "${order.payment?.amount?.toStringAsFixed(1) ?? "0"}",
  //     note: '',
  //   );
  //   printer.hr();
  //
  //   printer.text("${'invoice_number'.tr}:  ${order.invoice?.invoiceNumber ?? ''}",
  //     styles: PosStyles(align: PosAlign.left, bold: true),
  //   );
  //   printer.text("${'payment_method'.tr}:  ${order.payment?.paymentMethod ?? ''}",
  //     styles: PosStyles(align: PosAlign.left, bold: true),
  //   );
  //   printer.text("${'paid'.tr}: ${order.createdAt ?? ''}",
  //     styles: PosStyles(align: PosAlign.left, bold: true),
  //   );
  //   printer.hr();
  //
  //   if (order.brutto_netto_summary != null &&
  //       order.brutto_netto_summary!.isNotEmpty) {
  //     _printTaxSummary(printer, order);
  //   }
  //
  //   printer.feed(1);
  //   printer.cut();
  // }

  static Future<void> _printOrderDetails(NetworkPrinter printer, Order order, String? store) async {
    // String formatAmount(double amount) {
    //   final locale = Get.locale?.languageCode ?? 'en';
    //
    //   if (locale == 'de') {
    //     // German format: comma as decimal separator, dot as thousands separator
    //     return NumberFormat('#.##0,00#', 'de_DE').format(amount);
    //   } else {
    //     // English format: dot as decimal separator, comma as thousands separator
    //     return NumberFormat('#,##0.00#', 'en_US').format(amount);
    //   }
    // }
    String formatAmount(double? amount) {
      if (amount == null) return "0";

      final locale = Get.locale?.languageCode ?? 'en';
      String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
      return NumberFormat('#,##0.00#', localeToUse).format(amount);
    }
    final now = DateTime.now();
    final dateTimeStr = '${now.day}/${now.month}/${now.year},'
        ' ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    var amount = order.payment?.amount ?? 0.0;
    var discount = order.invoice?.discount_amount ?? 0.0;
    var delFee = order.invoice?.delivery_fee ?? 0.0;
    var preSubTotal = amount - discount +delFee;
    final subtotal = preSubTotal;

    final discountData = order.invoice?.discount_amount ?? 0.0;

    printer.text(" ${store ?? ''}",
      styles: PosStyles(align: PosAlign.center, bold: true),);

    printer.text("${'order'.tr} # ${order.id ?? ''}",
      styles: PosStyles(align: PosAlign.center, bold: true),
    );

    printer.setStyles(PosStyles(align: PosAlign.center));
    printer.text(
      sanitizeText("${'invoice_number'.tr}: ${order.invoice?.invoiceNumber ?? ''}"),
      styles: PosStyles(bold: true),
    );
    printer.text(
      sanitizeText("${'date'.tr}: ${order.createdAt ?? dateTimeStr}"),
      styles: PosStyles(bold: true),
    );
    printer.hr();
    printer.text(
      sanitizeText("${'customer'.tr}: ${(order.shipping_address?.customer_name ?? '')}"),
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text(
      "${'address'.tr}: ${order.shipping_address?.line1 ?? ""}, ${order.shipping_address?.city ?? ""}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text(
      "${'phone'.tr}: ${order.shipping_address?.phone ?? ""}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();
    printer.feed(1);

    _printOrderItems(printer, order);
    printer.hr();
    _printItemWithNote(
        printer: printer,
        left: "${'subtotal'.tr}:",
        right: formatAmount(subtotal),
        note: '');

    if (discountData != 0.0) {
      _printItemWithNote(
          printer: printer,
          left: "${'discount'.tr}:",
          right: formatAmount(discount),
          note: '');
    }

    if (delFee != 0.0) {
      _printItemWithNote(
          printer: printer,
          left: "${'delivery_fee'.tr}:",
          right: formatAmount(delFee),
          note: '');
    }

    printer.hr();
    _printItemWithNote(
      printer: printer,
      left: "${'grand_total'.tr}:",
      right: formatAmount(order.invoice?.totalAmount ?? 0.0),
      note: '',
    );
    printer.hr();

    printer.text("${'invoice_number'.tr}:  ${order.invoice?.invoiceNumber ?? ''}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text("${'payment_method'.tr}:  ${order.payment?.paymentMethod ?? ''}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text("${'paid'.tr}: ${order.createdAt ?? ''}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();

    if (order.brutto_netto_summary != null &&
        order.brutto_netto_summary!.isNotEmpty) {
      _printTaxSummary(printer, order);
    }

    printer.feed(1);
    printer.cut();
  }

  // static void _printOrderItems(NetworkPrinter printer, Order order) {
  //   if (order.items == null || order.items!.isEmpty) return;
  //
  //   for (final orderItem in order.items!) {
  //     final quantity = orderItem.quantity ?? 1;
  //     final productName = orderItem.productName ?? '';
  //     final unitPrice = orderItem.unitPrice ?? 0.0;
  //     final priceText = _formatCurrency(unitPrice * quantity);
  //
  //     _printItemWithNote(
  //       printer: printer,
  //       left: '$quantity $productName',
  //       right: orderItem.variant != null ? ' ' : '$priceText ',
  //       note: orderItem.note,
  //     );
  //
  //     if (orderItem.variant != null) {
  //       final variantName = sanitizeText(orderItem.variant!.name ?? '');
  //       final variantPrice = orderItem.variant!.price != null
  //           ? _formatCurrency(orderItem.variant!.price!)
  //           : '0,00';
  //       printer.text('$quantity x $variantName [$variantPrice]');
  //     }
  //     // Print Toppings
  //     if (orderItem.toppings != null && orderItem.toppings!.isNotEmpty) {
  //       for (final topping in orderItem.toppings!) {
  //         final tQty = topping.quantity ?? 1;
  //         final tName = sanitizeText(topping.name ?? '');
  //         final tPrice = _formatCurrency((topping.price ?? 0) * tQty);
  //         printer.text('  $tQty x $tName [$tPrice]');
  //       }
  //     }
  //     if (orderItem.note != null && orderItem.note!.trim().isNotEmpty) {
  //       printer.text('+ ${sanitizeText(orderItem.note!.trim())}');
  //     }
  //
  //     printer.feed(0);
  //   }
  // }
  static void _printOrderItems(NetworkPrinter printer, Order order) {
    if (order.items == null || order.items!.isEmpty) return;

    // Group items by product name
    Map<String, List<OrderItem>> groupedItems = {};
    for (var item in order.items!) {
      final productName = item.productName ?? '';
      if (!groupedItems.containsKey(productName)) {
        groupedItems[productName] = [];
      }
      groupedItems[productName]!.add(item);
    }

    // Print each grouped product
    for (final entry in groupedItems.entries) {
      final productName = entry.key;
      final items = entry.value;

      // Calculate total quantity and price for this product
      int totalQuantity = items.fold(0, (sum, item) => sum + (item.quantity ?? 0));

      double totalProductPrice = 0;
      for (var item in items) {
        final toppingTotal = item.toppings?.fold<double>(
          0,
              (sum, topping) => sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
        ) ?? 0.0;
        final itemTotal = ((item.unitPrice ?? 0) + toppingTotal) * (item.quantity ?? 0);
        totalProductPrice += itemTotal;
      }

      // Check if should show unit price (same condition as UI)
      bool shouldShowUnitPrice = items.any((item) =>
      (item.toppings?.isNotEmpty ?? false) && item.variant == null);

      final priceText = _formatCurrency(totalProductPrice);

      // Print main product line
      String productLine = '$totalQuantity $productName';
      if (shouldShowUnitPrice) {
        productLine += ' [${_formatCurrency(items.first.unitPrice ?? 0)}]';
      }

      _printItemWithNote(
        printer: printer,
        left: productLine,
        right: '$priceText ',
        note: '', // Main product note can be handled separately if needed
      );

      // Print all variants and toppings for this product
      for (final orderItem in items) {
        // Variant
        if (orderItem.variant != null) {
          final variantName = sanitizeText(orderItem.variant!.name ?? '');
          final variantPrice = orderItem.variant!.price != null
              ? _formatCurrency(orderItem.variant!.price!)
              : '0,00';
          printer.text('  ${orderItem.quantity} x $variantName [$variantPrice]');
        }

        // Toppings
        if (orderItem.toppings != null && orderItem.toppings!.isNotEmpty) {
          for (final topping in orderItem.toppings!) {
            final tQty = topping.quantity ?? 1;
            final tName = sanitizeText(topping.name ?? '');
            final tPrice = _formatCurrency((topping.price ?? 0) * tQty);
            printer.text('    $tQty x $tName [$tPrice]');
          }
        }

        // Note
        if (orderItem.note != null && orderItem.note!.trim().isNotEmpty) {
          printer.text('  + ${sanitizeText(orderItem.note!.trim())}');
        }
      }

      printer.feed(0);
    }
  }

  // static void _printTaxSummary(NetworkPrinter printer, Order order) {
  //   printer.text(
  //     '${'vat_rate'.tr}        ${'gross'.tr}       ${'net'.tr}       ${'vat'.tr}',
  //     styles: PosStyles(bold: true, align: PosAlign.left),
  //   );
  //
  //   for (var tax in order.brutto_netto_summary!) {
  //     _printTaxSummaryLine(
  //       printer: printer,
  //       left: '${tax.taxRate!.toStringAsFixed(0)} %',
  //       middle1: _formatCurrency(tax.brutto!),
  //       middle2: _formatCurrency(tax.netto!),
  //       right: _formatCurrency(tax.tax_amount!),
  //     );
  //   }
  //   printer.hr();
  //   printer.feed(1);
  // }

  static void _printTaxSummary(NetworkPrinter printer, Order order) {
    String formatAmount(double? amount) {
      if (amount == null) return "0";

      final locale = Get.locale?.languageCode ?? 'en';
      String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
      return NumberFormat('#,##0.00#', localeToUse).format(amount);
    }

    printer.text(
      '${'vat_rate'.tr}        ${'gross'.tr}       ${'net'.tr}       ${'vat'.tr}',
      styles: PosStyles(bold: true, align: PosAlign.left),
    );

    for (var tax in order.brutto_netto_summary!) {
      _printTaxSummaryLine(
        printer: printer,
        left: '${(tax.taxRate ?? 0.0).toStringAsFixed(0)} %',
        middle1: formatAmount(tax.brutto ?? 0.0),
        middle2: formatAmount(tax.netto ?? 0.0),
        right: formatAmount(tax.tax_amount ?? 0.0),
      );
    }
    printer.hr();
    printer.feed(1);
  }
  static void _printItemWithNote({
    required NetworkPrinter printer,
    required String left,
    required String right,
    String? note,
    int lineWidth = 48,
  }) {
    final availableWidth = lineWidth - right.length;

    if (left.length + right.length <= lineWidth) {
      final spaces = lineWidth - left.length - right.length;
      printer.text('$left${' ' * spaces}$right');
    } else {
      final leftLines = <String>[];
      String remaining = left;

      while (remaining.isNotEmpty) {
        if (remaining.length <= availableWidth) {
          leftLines.add(remaining);
          remaining = '';
        } else {
          int breakIndex = remaining.lastIndexOf(' ', availableWidth);
          if (breakIndex == -1) breakIndex = availableWidth;
          leftLines.add(remaining.substring(0, breakIndex).trimRight());
          remaining = remaining.substring(breakIndex).trimLeft();
        }
      }

      for (int i = 0; i < leftLines.length - 1; i++) {
        printer.text(leftLines[i]);
      }

      final lastLeft = leftLines.isNotEmpty ? leftLines.last : '';
      final spaces = lineWidth - lastLeft.length - right.length;
      final finalLine = '$lastLeft${' ' * (spaces >= 0 ? spaces : 0)}$right';
      printer.text(finalLine);
    }

    if (note != null && note.trim().isNotEmpty) {
      printer.text('+ ${note.trim()}');
    }
  }

  static void _printTaxSummaryLine({required NetworkPrinter printer, required String left, required String middle1, required String middle2, required String right}) {
    const col1 = 12;
    const col2 = 12;
    const col3 = 12;
    const col4 = 12;

    final leftStr = left.padRight(col1);
    final middle1Str = middle1.padLeft(col2);
    final middle2Str = middle2.padLeft(col3);
    final rightStr = right.padLeft(col4);

    final line = '$leftStr$middle1Str$middle2Str$rightStr';

    printer.text(line, styles: PosStyles(align: PosAlign.left));
  }

  static String sanitizeText(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  static String _formatCurrency(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  static void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

