import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/services/customer_service.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/storage/userStorage.dart';
import 'customer_detail.dart';
import 'customer_form.dart';
import 'bill_form.dart';

enum CustomerViewMode { table, grid }

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final CustomerService _customerService = CustomerService();
  final OrderService _orderService = OrderService();
  List<Customer> _customers = [];
  Map<String, List<Order>> _customerOrders = {};
  bool _isLoading = true;
  String _searchQuery = '';
  CustomerViewMode _viewMode = CustomerViewMode.table;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final sellerId = userStorage.currentUser?.id;
      if (sellerId != null) {
        _customers = await _customerService.fetchCustomers(sellerId);
        await _loadAllOrders(sellerId);
      }
    } catch (e) {
      // use cached
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadAllOrders(String sellerId) async {
    _customerOrders.clear();
    for (final customer in _customers) {
      try {
        final orders = await _orderService.fetchOrdersByCustomer(customer.id);
        _customerOrders[customer.id] = orders;
      } catch (e) {
        _customerOrders[customer.id] = [];
      }
    }
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) =>
        c.name.toLowerCase().contains(query) ||
        c.phone.contains(query)).toList();
  }

  List<Order> _getCustomerOrders(String customerId) {
    return _customerOrders[customerId] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == CustomerViewMode.table
                ? Icons.grid_view : Icons.table_chart),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == CustomerViewMode.table
                    ? CustomerViewMode.grid
                    : CustomerViewMode.table;
              });
            },
            tooltip: _viewMode == CustomerViewMode.table
                ? 'Switch to Grid View'
                : 'Switch to Table View',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredCustomers.isEmpty
              ? _buildEmpty()
              : _viewMode == CustomerViewMode.table
                  ? _buildTableView()
                  : _buildGridView(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No customers yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add customers to see them here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Orders')),
              DataColumn(label: Text('Total Spent')),
              DataColumn(label: Text('Last Purchase')),
              DataColumn(label: Text('Bills')),
            ],
            rows: _filteredCustomers.map((customer) {
              final orders = _getCustomerOrders(customer.id);
              return DataRow(
                onSelectChanged: (_) => _openCustomerDetail(customer),
                cells: [
                  DataCell(Text(customer.name)),
                  DataCell(Text(customer.phone)),
                  DataCell(Text('${customer.totalOrders}')),
                  DataCell(Text('EGP ${customer.totalSpent.toStringAsFixed(0)}')),
                  DataCell(Text(customer.lastPurchaseDate != null
                      ? '${customer.lastPurchaseDate!.day}/${customer.lastPurchaseDate!.month}/${customer.lastPurchaseDate!.year}'
                      : 'N/A')),
                  DataCell(Text('${orders.length} bills')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          return _CustomerGridTile(
            customer: customer,
            onTap: () => _openCustomerDetail(customer),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddOptions,
      child: const Icon(Icons.add),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add Customer'),
            onTap: () {
              Navigator.pop(context);
              _addCustomer();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Create Bill'),
            onTap: () {
              Navigator.pop(context);
              _createBill();
            },
          ),
        ],
      ),
    );
  }

  void _addCustomer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerFormPage(),
      ),
    ).then((_) => _loadCustomers());
  }

  void _createBill() {
    if (_customers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Customers'),
          content: const Text('You need to create a customer first before creating a bill.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addCustomer();
              },
              child: const Text('Create Customer'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return ListTile(
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillFormPage(customer: customer),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.blue),
                title: const Text('Create New Customer'),
                onTap: () {
                  Navigator.pop(context);
                  _addCustomer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailPage(customer: customer),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: _CustomerSearchDelegate(
        customers: _customers,
        onSelected: (customer) => _openCustomerDetail(customer),
      ),
    );
  }
}

class _CustomerGridTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerGridTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  customer.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                customer.phone,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'EGP ${customer.totalSpent.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final List<Customer> customers;
  final Function(Customer) onSelected;

  _CustomerSearchDelegate({required this.customers, required this.onSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = query.isEmpty
        ? customers
        : customers.where((c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.phone.contains(query)).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final customer = results[index];
        return ListTile(
          leading: CircleAvatar(child: Text(customer.initials)),
          title: Text(customer.name),
          subtitle: Text(customer.phone),
          onTap: () {
            close(context, customer);
            onSelected(customer);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Items: ${order.totalItems}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              order.createdAt.toString().split('.')[0],
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(color: Colors.grey[600])),
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
      ),
    );
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