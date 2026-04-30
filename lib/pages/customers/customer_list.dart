import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/services/customer_service.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/storage/bill_vault_storage.dart';
import 'customer_detail.dart';
import 'customer_form.dart';
import 'bill_form.dart';
import 'customer_bills_page.dart';

enum CustomerViewMode { table, grid }

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  Map<String, List<Order>> _customerOrders = {};
  bool _isLoading = true;
  String _searchQuery = '';
  CustomerViewMode _viewMode = CustomerViewMode.grid;
  final Set<String> _expandedCustomers = {};

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final sellerId = userStorage.currentUser?.id;
      if (sellerId != null) {
        _customers = await _customerService.fetchCustomers(sellerId);
        await _loadAllOrders(sellerId);
      }
    } catch (e) {
      debugPrint('[CustomerList._loadCustomers] Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAllOrders(String sellerId) async {
    _customerOrders.clear();
    final vault = await BillVaultStorage.getInstance();
    final allBills = vault.getSellerBills(sellerId);

    for (final customer in _customers) {
      final customerBills = allBills
          .where((o) => o.userId == customer.id)
          .toList();
      _customerOrders[customer.id] = customerBills;
    }
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(query) || c.phone.contains(query),
        )
        .toList();
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
            icon: Icon(
              _viewMode == CustomerViewMode.table
                  ? Icons.grid_view
                  : Icons.table_chart,
            ),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          final orders = _getCustomerOrders(customer.id);
          final isExpanded = _expandedCustomers.contains(customer.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ExpansionTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  customer.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              title: Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(customer.phone),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EGP ${customer.totalSpent.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '${orders.length} bills',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  if (expanded) {
                    _expandedCustomers.add(customer.id);
                  } else {
                    _expandedCustomers.remove(customer.id);
                  }
                });
              },
              children: [
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No bills for this customer',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, billIndex) {
                      final order = orders[billIndex];
                      return _BillListTile(order: order);
                    },
                  ),
              ],
            ),
          );
        },
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
            onTap: () => _openCustomerBills(customer),
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
    ).then((result) {
      if (result != null) {
        debugPrint('[CustomerList._addCustomer] Customer created: ${result.name}');
        _loadCustomers();
      }
    });
  }

  void _createBill() {
    if (_customers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Customers'),
          content: const Text(
            'You need to create a customer first before creating a bill.',
          ),
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
                      leading: CircleAvatar(child: Text(customer.initials)),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BillFormPage(customer: customer),
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

  void _openCustomerBills(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerBillsPage(customer: customer),
      ),
    ).then((_) => _loadCustomers());
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: _CustomerSearchDelegate(
        customers: _customers,
        onSelected: (customer) => _openCustomerBills(customer),
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

class _BillListTile extends StatelessWidget {
  final Order order;

  const _BillListTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getStatusColor(order.status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.receipt_long,
          color: _getStatusColor(order.status),
          size: 20,
        ),
      ),
      title: Text(
        'Bill #${order.id.substring(0, 8)}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${_formatDate(order.createdAt)} • ${order.paymentMethod.value.toUpperCase()}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'EGP ${order.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          _StatusBadge(status: order.status),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status.value) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final List<Customer> customers;
  final Function(Customer) onSelected;

  _CustomerSearchDelegate({required this.customers, required this.onSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
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
        : customers
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query.toLowerCase()) ||
                    c.phone.contains(query),
              )
              .toList();

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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
