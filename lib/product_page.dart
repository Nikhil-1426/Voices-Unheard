import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'community_page.dart';
import 'education_page.dart';
import 'settings_page.dart';
import 'package:voices_unheard/app_colors.dart';

// Enum for managing tab state
enum ProductPageTab { shop, sell, history, cart }

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // Initialize Supabase client
  final supabase = Supabase.instance.client;
  
  // Current selected tab
  ProductPageTab _currentTab = ProductPageTab.shop;
  
  // Loading states
  bool _isLoading = false;
  String? _error;

  // Data holders
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _orderHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Load initial data based on current tab
  Future<void> _loadInitialData() async {
    await _fetchProducts();
    await _fetchCartItems();
    await _fetchOrderHistory();
  }

  // Fetch products from Supabase
  Future<void> _fetchProducts() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await supabase
          .from('products')
          .select('*')  // Simplified query
          .order('created_at', ascending: false);
      
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _error = null; // Clear any previous errors
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        _error = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  // Fetch cart items
  Future<void> _fetchCartItems() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('cart')
          .select('*, products(*)')
          .eq('user_id', userId);

      setState(() {
        _cartItems = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cart items';
      });
    }
  }

  // Fetch order history
  Future<void> _fetchOrderHistory() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('buyer_id', userId)
          .order('order_date', ascending: false);

      setState(() {
        _orderHistory = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load order history';
      });
    }
  }

  // Add to cart function
  Future<void> _addToCart(String productId, {int quantity = 1}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check if item already exists in cart
      final existingItem = _cartItems.firstWhere(
        (item) => item['product_id'] == productId,
        orElse: () => {},
      );

      if (existingItem.isNotEmpty) {
        // Update quantity
        await supabase
            .from('cart')
            .update({'quantity': existingItem['quantity'] + quantity})
            .eq('id', existingItem['id']);
      } else {
        // Add new item
        await supabase.from('cart').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'added_at': DateTime.now().toIso8601String(),
        });
      }

      await _fetchCartItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to cart')),
      );
    }
  }

  // Dummy payment processing
  Future<void> _processDummyPayment(double totalAmount) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Create new order
      final orderResponse = await supabase
          .from('orders')
          .insert({
            'buyer_id': userId,
            'order_date': DateTime.now().toIso8601String(),
            'total_amount': totalAmount,
            'status': 'pending',
            'delivery_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'address': '123 Sample Street', // In real app, get from user input
          })
          .select()
          .single();

      // Add order items
      for (final cartItem in _cartItems) {
        await supabase.from('order_items').insert({
          'order_id': orderResponse['id'],
          'product_id': cartItem['product_id'],
          'quantity': cartItem['quantity'],
          'item_price': cartItem['products']['price'],
        });
      }

      // Clear cart
      await supabase
          .from('cart')
          .delete()
          .eq('user_id', userId);

      // Refresh data
      await _fetchCartItems();
      await _fetchOrderHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<ProductPageTab>(
              segments: const [
                ButtonSegment(
                  value: ProductPageTab.shop,
                  label: Text('Shop'),
                  icon: Icon(Icons.shop),
                ),
                ButtonSegment(
                  value: ProductPageTab.sell,
                  label: Text('Sell'),
                  icon: Icon(Icons.sell),
                ),
                ButtonSegment(
                  value: ProductPageTab.history,
                  label: Text('History'),
                  icon: Icon(Icons.history),
                ),
                ButtonSegment(
                  value: ProductPageTab.cart,
                  label: Text('Cart'),
                  icon: Icon(Icons.shopping_cart),
                ),
              ],
              selected: {_currentTab},
              onSelectionChanged: (Set<ProductPageTab> newSelection) {
                setState(() {
                  _currentTab = newSelection.first;
                });
              },
            ),
          ),
          // Error display
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          // Loading indicator
          if (_isLoading)
            const CircularProgressIndicator()
          else
            // Content based on selected tab
            Expanded(
              child: _buildTabContent(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case ProductPageTab.shop:
        return _buildShopTab();
      case ProductPageTab.sell:
        return _buildSellTab();
      case ProductPageTab.history:
        return _buildHistoryTab();
      case ProductPageTab.cart:
        return _buildCartTab();
    }
  }

  Widget _buildShopTab() {
  if (_products.isEmpty) {
    return const Center(
      child: Text('No products available'),
    );
  }

  return GridView.builder(
    padding: const EdgeInsets.all(8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: _products.length,
    itemBuilder: (context, index) {
      final product = _products[index];
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Placeholder color
                ),
                child: product['image_url'] != null
                    ? Image.network(
                        product['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      )
                    : const Icon(Icons.image_not_supported),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unnamed Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${product['price']?.toString() ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _addToCart(product['id']),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Cart'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _processDummyPayment(
                            double.parse(product['price'].toString())),
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('Buy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildSellTab() {
    // Form controllers
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final imageUrlController = TextEditingController();
    final stockController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stock Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: imageUrlController,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final userId = supabase.auth.currentUser?.id;
                if (userId == null) return;

                await supabase.from('products').insert({
                  'seller_id': userId,
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'price': double.parse(priceController.text),
                  'image_url': imageUrlController.text,
                  'stock': int.parse(stockController.text),
                  'created_at': DateTime.now().toIso8601String(),
                });

                await _fetchProducts();
                
                // Clear form
                nameController.clear();
                descriptionController.clear();
                priceController.clear();
                imageUrlController.clear();
                stockController.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product listed successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to list product')),
                );
              }
            },
            icon: const Icon(Icons.upload),
            label: const Text('List Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      itemCount: _orderHistory.length,
      itemBuilder: (context, index) {
        final order = _orderHistory[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text('Order #${order['id'].substring(0, 8)}'),
            subtitle: Text(
              'Status: ${order['status']} - ${DateTime.parse(order['order_date']).toString().substring(0, 16)}',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Amount: \$${order['total_amount']}'),
                    Text('Delivery Date: ${DateTime.parse(order['delivery_date']).toString().substring(0, 16)}'),
                    Text('Shipping Address: ${order['address']}'),
                    const Divider(),
                    const Text(
                      'Items:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...order['order_items'].map<Widget>((item) {
                      return ListTile(
                        title: Text(item['products']['name']),
                        subtitle: Text('Quantity: ${item['quantity']}'),
                        trailing: Text('\$${item['item_price']}'),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Continuation of _buildCartTab() function
    Widget _buildCartTab() {
      double total = 0;
      for (var item in _cartItems) {
        total += (item['products']['price'] * item['quantity']);
      }

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                final product = item['products'];
                final itemTotal = product['price'] * item['quantity'];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(
                      product['image_url'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(product['name']),
                    subtitle: Text('\$${product['price']} x ${item['quantity']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${itemTotal.toStringAsFixed(2)}'),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateCartItemQuantity(item['id'], item['quantity'] - 1),
                        ),
                        Text('${item['quantity']}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateCartItemQuantity(item['id'], item['quantity'] + 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _cartItems.isEmpty
                        ? null
                        : () => _processDummyPayment(total),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Checkout'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Helper function to update cart item quantity
    Future<void> _updateCartItemQuantity(String cartItemId, int newQuantity) async {
      try {
        if (newQuantity <= 0) {
          // Remove item if quantity is 0 or less
          await supabase
              .from('cart')
              .delete()
              .eq('id', cartItemId);
        } else {
          // Update quantity
          await supabase
              .from('cart')
              .update({'quantity': newQuantity})
              .eq('id', cartItemId);
        }
        await _fetchCartItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update cart')),
        );
      }
    }

    Widget _buildBottomNavigationBar(BuildContext context) {
      return BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_rounded),
            label: 'Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_sharp),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.house_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_rounded),
            label: 'Education',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: AppColors.colors['accent2'],
        unselectedItemColor: AppColors.colors['primary'],
        backgroundColor: Colors.white,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        onTap: (index) {
          Widget page;
          switch (index) {
            case 0:
              page = const ProductPage();
              break;
            case 1:
              page = const CommunityPage();
              break;
            case 2:
              page = const HomePage();
              break;
            case 3:
              page = EducationPage();
              break;
            case 4:
              page = const SettingsPage();
              break;
            default:
              return;
          }
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
      );
    }
}