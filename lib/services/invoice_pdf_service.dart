import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoicePdfService {
  Future<void> previewInvoice({
    required Order order,
    Customer? customer,
  }) async {
    final bytes = await buildInvoice(order: order, customer: customer);
    await Printing.layoutPdf(
      name: 'aurora_invoice_${order.id}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<Uint8List> buildInvoice({
    required Order order,
    Customer? customer,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final sellerName =
        metadata['store_name']?.toString().trim().isNotEmpty == true
        ? metadata['store_name'].toString()
        : metadata['full_name']?.toString() ?? 'Aurora Seller';
    final sellerEmail = user?.email ?? '';
    final dateFormat = DateFormat('MMM d, yyyy');

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    sellerName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (sellerEmail.isNotEmpty) pw.Text(sellerEmail),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo,
                    ),
                  ),
                  pw.Text('#${_shortId(order.id)}'),
                  pw.Text(dateFormat.format(order.createdAt)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryBlock('Bill To', [
                  customer?.name ?? 'Customer ${_shortId(order.userId)}',
                  if (customer?.phone.isNotEmpty == true) customer!.phone,
                  if (customer?.email?.isNotEmpty == true) customer!.email!,
                ]),
                _summaryBlock('Payment', [
                  order.paymentMethod.value.toUpperCase(),
                  'Status: ${order.paymentStatus.value}',
                  'Order: ${order.status.value}',
                ], alignEnd: true),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.TableHelper.fromTextArray(
            border: null,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellHeight: 32,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: ['Item', 'Qty', 'Unit', 'Total'],
            data: order.items.map((item) {
              return [
                item.productName,
                item.quantity.toString(),
                _money(item.unitPrice),
                _money(item.totalPrice),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', order.subtotal),
                  _totalRow('Discount', -order.discount),
                  _totalRow('Tax', order.tax),
                  _totalRow('Shipping', order.shipping),
                  pw.Divider(),
                  _totalRow('Total', order.total, bold: true),
                ],
              ),
            ),
          ),
          if (order.notes?.isNotEmpty == true) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'Notes',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(order.notes!),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _summaryBlock(
    String title,
    List<String> lines, {
    bool alignEnd = false,
  }) {
    return pw.Column(
      crossAxisAlignment: alignEnd
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        ...lines
            .where((line) => line.trim().isNotEmpty)
            .map((line) => pw.Text(line)),
      ],
    );
  }

  pw.Widget _totalRow(String label, double value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: bold ? 14 : 11,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(_money(value), style: style),
        ],
      ),
    );
  }

  static String _money(double value) => 'EGP ${value.toStringAsFixed(2)}';

  static String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}
