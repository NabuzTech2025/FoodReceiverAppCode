import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No printer selected.')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    final ip = prefs.getString('printer_ip_$selectedIndex');
    if (ip == null || ip.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected printer IP is empty.')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final result = await printer.connect(ip, port: 9100);

      if (result == PosPrintResult.success) {
        final now = DateTime.now();

        printer.text(
          ' ${now.day}/${now.month}/${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} pm',
          styles: PosStyles(align: PosAlign.right),
        );
        printer.feed(1);
        printer.text(
          store != null ? store : 'Restaurant',
          styles: PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );

        printer.setStyles(PosStyles(align: PosAlign.center));
        printer.text(
            sanitizeText(order.shipping_address?.customer_name ?? 'No user'),
            styles: (PosStyles(align: PosAlign.center, bold: true)));
        printer.text(sanitizeText(order.shipping_address?.city ?? 'Franklin'),
            styles: (PosStyles(align: PosAlign.center, bold: true)));
        printer.text(
            sanitizeText(order.shipping_address?.phone ?? '5555555555'),
            styles: (PosStyles(align: PosAlign.center, bold: true)));
        printer.text('Bestellnummer : ${order.id}',
            styles: (PosStyles(align: PosAlign.center, bold: true)));
        printer.hr();
        printer.feed(1);
        printer.text(
          '${order.orderType == 1 ? 'Delivery' : order.orderType == 2 ? 'Pickup' : order.orderType == 3 ? 'Dine-In' : ''}',
          styles: PosStyles(align: PosAlign.center, bold: true),
        );
        printer.text(
          'Bestätigte Zeit: ${now.day}/${now.month}/${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} pm',
          styles: PosStyles(align: PosAlign.center),
        );

        printer.feed(1);
        printer.setStyles(PosStyles(align: PosAlign.left, bold: true));
        printer.text(
            sanitizeText(order.shipping_address?.customer_name ?? 'No name'));
        printer.text(sanitizeText(order.shipping_address?.phone ?? 'No phone'));
        printer.hr();
        printer.feed(1);

        if (order.items != null && order.items!.isNotEmpty) {
          for (final orderItem in order.items!) {
            final quantity = orderItem.quantity ?? 1;
            final productName = orderItem.productName ?? '';
            final unitPrice = orderItem.unitPrice ?? 0.0;
            final priceText = formatCurrency(unitPrice * quantity);

            printItemWithNote(
              printer: printer,
              left: '$quantity $productName',
              right: orderItem.variant != null ? ' ' : '$priceText ',
              note: orderItem.note,
            );

            if (orderItem.variant != null) {
              final variantName = sanitizeText(orderItem.variant!.name ?? '');
              final variantPrice = orderItem.variant!.price != null
                  ? formatCurrency(orderItem.variant!.price!)
                  : '0,00';
              final variantLine = '$quantity x $variantName [$variantPrice ]';
              printer.text(variantLine);
            }

            if (orderItem.note != null && orderItem.note!.trim().isNotEmpty) {
              printer.text('+ ${sanitizeText(orderItem.note!.trim())}');
            }

            printer.feed(0);
          }
        }
        printer.hr();
        printer.hr();

        /* final amount = order.payment?.amount ?? 0.0;
        final discount = order.invoice?.discount_amount ?? 0.0;
        final delFee = order.invoice?.delivery_fee ?? 0.0;*/

        var amount = (order.payment?.amount ?? 0.0).toStringAsFixed(1);
        var discount =
            (order.invoice?.discount_amount ?? 0.0).toStringAsFixed(1);
        var delFee = (order.invoice?.delivery_fee ?? 0.0).toStringAsFixed(1);

// Since amount, discount, and delFee are now strings, convert them back to double to calculate subTotal
        var preSubTotal = (double.parse(amount) +
                double.parse(discount) -
                double.parse(delFee))
            .toStringAsFixed(1);
        final subtotal = preSubTotal;

        final discountData = order.invoice?.discount_amount ?? 0.0;
        final deliveryFee = formatCurrency(order.invoice?.delivery_fee ?? 0.0);
        // final subtotal = formatCurrency(amount + discount - delFee);
        final discountStr = formatCurrency(discountData);

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

        /*if (order.taxSummary != null && order.taxSummary!.isNotEmpty) {
          for (var tax in order.taxSummary!) {
            final rate = tax.taxRate?.toStringAsFixed(1) ?? "0.0";
            final amount =
                tax.taxAmount != null ? formatCurrency(tax.taxAmount!) : '0,00';
            final line = 'Tax ($rate%):  $amount';
            printer.text(
              line,
              styles: PosStyles(bold: true, align: PosAlign.right),
            );
          }
        }*/

        final total = order.payment?.amount != null
            ? formatCurrency(order.payment!.amount!)
            : '0,00';

        printer.text(
          'Total:     $total',
          styles: PosStyles(bold: true, align: PosAlign.right),
        );
        printer.hr();
        printer.feed(1);

        if (order.brutto_netto_summary != null &&
            order.brutto_netto_summary!.isNotEmpty) {
          printer.text(
            'MWSt-Satz       Brutto      Netto      MWSt',
            styles: PosStyles(bold: true, align: PosAlign.left),
          );

          for (var tax in order.brutto_netto_summary!) {
            printTaxSummaryLine(
              printer: printer,
              left: '${tax.taxRate!.toStringAsFixed(0)} %',
              middle1: formatCurrency(tax.brutto!),
              middle2: formatCurrency(tax.netto!),
              right: formatCurrency(tax.tax_amount!),
            );
          }
        }

        printer.hr();
        printer.feed(1);

        printer.text('Zahlungsmethode: Barzahlung',
            styles: (PosStyles(align: PosAlign.center, bold: false)));
        printer.text('Bestellung wurde nicht online bezahlt',
            styles: (PosStyles(align: PosAlign.center, bold: false)));

        printer.feed(1);
        printer.cut();
        printer.disconnect();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print success!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $result')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e')),
      );
      Navigator.of(context).pop(true);
    }
  }

  static void printTaxSummaryLine({
    required NetworkPrinter printer,
    required String left,
    required String middle1,
    required String middle2,
    required String right,
    int totalWidth = 48,
  }) {
    const col1 = 11;
    const col2 = 11;
    const col3 = 11;
    const col4 = 11;

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

  static String formatLineLeftRight(String left, String right,
      {int width = 48}) {
    if ((left.length + right.length) >= width) {
      return '${left.substring(0, width - right.length - 1)} ${right}';
    }
    final spaces = width - left.length - right.length;
    return '$left${' ' * spaces}$right';
  }

  static void printItemWithNote({
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

    printer.feed(1);
  }

  static String formatCurrency(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
