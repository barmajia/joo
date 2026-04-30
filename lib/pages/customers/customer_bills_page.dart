import 'package:flutter/material.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/storage/bill_vault_storage.dart';
import 'bill_form.dart';

class CustomerBillsPage extends StatefulWidget {
  final Customer customer;

  const CustomerBillsPage({super.key, required this.customer});

  @override
  State<CustomerBillsPage> createState() => _CustomerBillsPageState();
}

class _CustomerBillsPageState extends State<CustomerBillsPage> {
  final OrderService _orderService = OrderService();
  List<Order> _bills = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final vault = await BillVaultStorage.getInstance();
      final bills = vault.getCustomerBills(widget.customer.id);
      if (bills.isEmpty) {
        final fetched = await _orderService.fetchOrdersByCustomer(widget.customer.id);
        if (fetched.isNotEmpty) {
          await vault.saveCustomerBills(widget.customer.id, fetched);
          setState(() => _bills = fetched);
        } else {
          setState(() => _bills = []);
        }
      } else {
        setState(() => _bills = bills);
      }
    } catch (e) {
      debugPrint('[CustomerBillsPage._loadBills] Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Order> get _filteredBills {
    if (_filterStatus == 'all') return _bills;
    return _bills.where((o) => o.status.value == _filterStatus).toList();
  }

  Future<void> _refreshBills() async {
    await _loadBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bills', style: TextStyle(fontSize: 16)),
            Text(
              widget.customer.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
              const PopupMenuItem(value: 'processing', child: Text('Processing')),
              const PopupMenuItem(value: 'shipped', child: Text('Shipped')),
              const PopupMenuItem(value: 'delivered', child: Text('Delivered')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredBills.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _refreshBills,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredBills.length,
                    itemBuilder: (context, index) {
                      final order = _filteredBills[index];
                      return _BillCard(
                        order: order,
                        onTap: () => _viewBillDetail(order),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createBill(),
        child: const Icon(Icons.add),
        tooltip: 'Create Bill',
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'all'
                ? 'No bills for this customer'
                : 'No ${_filterStatus} bills',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new bill',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _createBill() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillFormPage(customer: widget.customer),
      ),
    ).then((_) => _refreshBills());
  }

  void _viewBillDetail(Order order) {
    showDialog(
      context: context,
      builder: (context) => _BillDetailDialog(order: order),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _BillCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Bill #${order.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shopping_basket, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${order.totalItems} item(s)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  order.notes!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        order.paymentMethod.value.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        'EGP ${order.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status.value) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'Confirmed';
        break;
      case 'processing':
        color = Colors.blue;
        text = 'Processing';
        break;
      case 'shipped':
        color = Colors.purple;
        text = 'Shipped';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'Delivered';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status.value;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _BillDetailDialog extends StatelessWidget {
  final Order order;

  const _BillDetailDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bill #${order.id.substring(0, 8)}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Status', order.status.value),
            _detailRow('Subtotal', 'EGP ${order.subtotal.toStringAsFixed(2)}'),
            _detailRow('Discount', 'EGP ${order.discount.toStringAsFixed(2)}'),
            _detailRow('Tax', 'EGP ${order.tax.toStringAsFixed(2)}'),
            _detailRow('Shipping', 'EGP ${order.shipping.toStringAsFixed(2)}'),
            const Divider(),
            _detailRow(
              'Total',
              'EGP ${order.total.toStringAsFixed(2)}',
              bold: true,
            ),
            const SizedBox(height: 8),
            _detailRow('Payment', order.paymentMethod.value),
            _detailRow('Payment Status', order.paymentStatus.value),
            _detailRow('Created', _formatDate(order.createdAt)),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
              Text(order.notes!, style: TextStyle(color: Colors.grey[600])),
            ],
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} x${item.quantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          'EGP ${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
