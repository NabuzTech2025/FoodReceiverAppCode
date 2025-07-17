import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';

class PrinterHelper {
  static Future<void> printTestFromSavedIp({
    required BuildContext context,
    required Order order,
    required String? store,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedIndex = prefs.getInt('selected_ip_index');
    if (selectedIndex == null) {
      _showSnackbar(context, 'No printer selected.');
      Navigator.of(context).pop(true);
      return;
    }

    final ip = prefs.getString('printer_ip_$selectedIndex');
    if (ip == null || ip.trim().isEmpty) {
      _showSnackbar(context, 'Selected printer IP is empty.');
      Navigator.of(context).pop(true);
      return;
    }

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final result = await printer.connect(ip, port: 9100);

      if (result == PosPrintResult.success) {
        await _printOrderDetails(printer, order, store);
        printer.disconnect();
        _showSnackbar(context, 'Print success!');
        Navigator.of(context).pop(true);
      } else {
        _showSnackbar(context, 'Print failed: $result');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showSnackbar(context, 'Print error: $e');
      Navigator.of(context).pop(true);
    }
  }

  static Future<void> _printOrderDetails(
      NetworkPrinter printer, Order order, String? store) async {
    final now = DateTime.now();
    final dateTimeStr =
        '${now.day}/${now.month}/${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} pm';
    var amount = (order.payment?.amount ?? 0.0).toStringAsFixed(1);
    var discount = (order.invoice?.discount_amount ?? 0.0).toStringAsFixed(1);
    var delFee = (order.invoice?.delivery_fee ?? 0.0).toStringAsFixed(1);
    var preSubTotal =
        (double.parse(amount) + double.parse(discount) - double.parse(delFee))
            .toStringAsFixed(1);
    final subtotal = preSubTotal;

    final discountData = order.invoice?.discount_amount ?? 0.0;
    // Print header
    //printer.text(dateTimeStr, styles: PosStyles(align: PosAlign.right));
    // printer.feed(1);
    printer.text(
      " ${store ?? ''}",
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    printer.text(
      "Order # ${order.id ?? ''}",
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    // Print customer info
    printer.setStyles(PosStyles(align: PosAlign.center));
    printer.text(
      //sanitizeText("Rcchnungsnr: ${order.invoice}"),
      sanitizeText("Rcchnungsnr: ${order.invoice?.invoiceNumber ?? ''}"),
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    printer.text(
      sanitizeText("Datum: ${order.createdAt ?? ''}"),
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    printer.hr();
    printer.text(
      sanitizeText("Kunde: ${order.shipping_address?.customer_name ?? ""}"),
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text(
      "Address: ${order.shipping_address?.line1 ?? ""}, ${order.shipping_address?.city ?? ""}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text(
      "Telefon: ${order.shipping_address?.phone ?? ""}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();
    printer.feed(1);

    // Print items
    _printOrderItems(printer, order);
    printer.hr();
    _printItemWithNote(
      printer: printer,
      left: "${'subtotal'.tr}:",
      right: subtotal, note: '',
    );
    if (discountData != 0.0) {
      _printItemWithNote(
        printer: printer,
        left: "${'discount'.tr}:",
        right: discount,
        note: '',
      );
    }
    //if (delFee != "0.0")
    if (delFee != 0.0){
      _printItemWithNote(
        printer: printer,
        left: "${'delivery_fee'.tr}:",
        right: delFee,
        note: '',
      );
    }
    printer.hr();
    _printItemWithNote(
      printer: printer,
      left: "Gesamt:",
      right: "${order.invoice?.totalAmount?.toStringAsFixed(1) ?? "0"} ",
      //right: "${order.payment?.amount?.toStringAsFixed(1) ?? "0"} ",
      note: '',
    );
    printer.hr();
    printer.text(
      "Rcchnungsnr:  ${order.invoice!.invoiceNumber.toString()}",
     // "Rcchnungsnr:  ${order.invoice?.invoiceNumber ?? ''}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text(
      "Zahlungsart:  ${order.payment?.paymentMethod ?? ''}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.text(
      "Bezahlt: ${order.createdAt ?? ''}",
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    printer.hr();
    // Print summary
    //_printOrderSummary(printer, order);

    // Print tax summary if available
    if (order.brutto_netto_summary != null &&
        order.brutto_netto_summary!.isNotEmpty) {
      _printTaxSummary(printer, order);
    }
    printer.feed(1);
    // Print payment info
    printer.cut();
  }

  static void _printOrderItems(NetworkPrinter printer, Order order) {
    if (order.items == null || order.items!.isEmpty) return;

    for (final orderItem in order.items!) {
      final quantity = orderItem.quantity ?? 1;
      final productName = orderItem.productName ?? '';
      final unitPrice = orderItem.unitPrice ?? 0.0;
      final priceText = _formatCurrency(unitPrice * quantity);

      _printItemWithNote(
        printer: printer,
        left: '$quantity $productName',
        right: orderItem.variant != null ? ' ' : '$priceText ',
        note: orderItem.note,
      );

      if (orderItem.variant != null) {
        final variantName = sanitizeText(orderItem.variant!.name ?? '');
        final variantPrice = orderItem.variant!.price != null
            ? _formatCurrency(orderItem.variant!.price!)
            : '0,00';
  //       final variantLine = '$quantity x $variantName [$variantPrice ]';
  //       printer.text(variantLine);
  //     }
  //
  //     if (orderItem.note != null && orderItem.note!.trim().isNotEmpty) {
  //       printer.text('+ ${sanitizeText(orderItem.note!.trim())}');
  //     }
  //
  //     printer.feed(0);
  //   }
  // }
        printer.text('$quantity x $variantName [$variantPrice]');
      }
      // Print Toppings
      if (orderItem.toppings != null && orderItem.toppings!.isNotEmpty) {
        for (final topping in orderItem.toppings!) {
          final tQty = topping.quantity ?? 1;
          final tName = sanitizeText(topping.name ?? '');
          final tPrice = _formatCurrency((topping.price ?? 0) * tQty);
          printer.text('  $tQty x $tName [$tPrice]');
        }
      }
      if (orderItem.note != null && orderItem.note!.trim().isNotEmpty) {
        printer.text('+ ${sanitizeText(orderItem.note!.trim())}');
      }

      printer.feed(0);
    }
  }

  static void _printOrderSummary(NetworkPrinter printer, Order order) {
    var amount = (order.payment?.amount ?? 0.0).toStringAsFixed(1);
    var discount = (order.invoice?.discount_amount ?? 0.0).toStringAsFixed(1);
    var delFee = (order.invoice?.delivery_fee ?? 0.0).toStringAsFixed(1);
    var preSubTotal =
        (double.parse(amount) + double.parse(discount) - double.parse(delFee))
            .toStringAsFixed(1);
    final subtotal = preSubTotal;
    final discountStr = _formatCurrency(order.invoice?.discount_amount ?? 0.0);
    final deliveryFee = _formatCurrency(order.invoice?.delivery_fee ?? 0.0);

    printer.text(
      'Subtotal:         $subtotal',
      styles: PosStyles(bold: true, align: PosAlign.right),
    );

    printer.text(
      'Discount:         $discountStr',
      styles: PosStyles(bold: true, align: PosAlign.right),
    );

    printer.text(
      'Delivery Fee:     $deliveryFee',
      styles: PosStyles(bold: true, align: PosAlign.right),
    );

    final total = order.payment?.amount != null
        ? _formatCurrency(order.payment!.amount!)
        : '0,00';

    printer.text(
      'Total:     $total',
      styles: PosStyles(bold: true, align: PosAlign.right),
    );
    printer.hr();
    printer.feed(1);
  }

  static void _printTaxSummary(NetworkPrinter printer, Order order) {
    printer.text(
      'MWSt-Satz          Brutto         Netto         MWSt',
      styles: PosStyles(bold: true, align: PosAlign.left),
    );

    for (var tax in order.brutto_netto_summary!) {
      _printTaxSummaryLine(
        printer: printer,
        left: '${tax.taxRate!.toStringAsFixed(0)} %',
        middle1: _formatCurrency(tax.brutto!),
        middle2: _formatCurrency(tax.netto!),
        right: _formatCurrency(tax.tax_amount!),
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

  static void _printTaxSummaryLine({
    required NetworkPrinter printer,
    required String left,
    required String middle1,
    required String middle2,
    required String right,
  }) {
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

  static String _getOrderTypeText(int? orderType) {
    switch (orderType) {
      case 1:
        return 'Delivery';
      case 2:
        return 'Pickup';
      case 3:
        return 'Dine-In';
      default:
        return '';
    }
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
