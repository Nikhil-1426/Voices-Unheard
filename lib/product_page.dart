// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at
// https://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'community_page.dart';
import 'education_page.dart';
import 'settings_page.dart';
import 'package:voices_unheard/app_colors.dart';

enum ProductPageTab { shop, sell, history, cart }

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final supabase = Supabase.instance.client;
  ProductPageTab _currentTab = ProductPageTab.shop;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _orderHistory = [];
  final int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // [Previous methods remain unchanged: _loadInitialData, _fetchProducts, _fetchCartItems,
  // _fetchOrderHistory, _addToCart, _processDummyPayment]
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
          .select('*') // Simplified query
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
            .update({'quantity': existingItem['quantity'] + quantity}).eq(
                'id', existingItem['id']);
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
            'delivery_date':
                DateTime.now().add(const Duration(days: 7)).toIso8601String(),
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
      await supabase.from('cart').delete().eq('user_id', userId);

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
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.colors['background'],
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            "Products",
            style: TextStyle(
              color: AppColors.colors['accent2'],
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.colors['accent1']!.withOpacity(0.05),
                      AppColors.colors['accent3']!.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SegmentedButton<ProductPageTab>(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppColors.colors['accent5']!
                                .withOpacity(0.9);
                          }
                          return Colors.white;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return AppColors.colors['primary']!;
                        },
                      ),
                      visualDensity: VisualDensity.comfortable,
                      elevation: MaterialStateProperty.all(0),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    segments: [
                      ButtonSegment(
                        value: ProductPageTab.shop,
                        label: const Text('Shop',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600)),
                        icon: const Icon(Icons.shop, size: 16),
                      ),
                      ButtonSegment(
                        value: ProductPageTab.sell,
                        label: const Text('Sell',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600)),
                        icon: const Icon(Icons.sell, size: 16),
                      ),
                      ButtonSegment(
                        value: ProductPageTab.history,
                        label: const Text('History',
                            style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w600)),
                        icon: const Icon(Icons.history, size: 14),
                      ),
                      ButtonSegment(
                        value: ProductPageTab.cart,
                        label: const Text('Cart',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600)),
                        icon: const Icon(Icons.shopping_cart, size: 16),
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
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.colors['accent2']),
                ),
              ),
            if (_isLoading)
              CircularProgressIndicator(color: AppColors.colors['accent2'])
            else
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.colors['accent2'],
                  onRefresh: _loadInitialData,
                  child: _buildTabContent(),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.colors['background']!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
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
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.colors['accent2'],
            unselectedItemColor: AppColors.colors['primary'],
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
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
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShopTab() {
    if (_products.isEmpty) {
      return Center(
        child: Text(
          'No products available',
          style: TextStyle(color: AppColors.colors['primary']),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.colors['accent2']!.withOpacity(0.1),
                        AppColors.colors['accent1']!.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: product['image_url'] != null
                      ? Image.network(
                          product['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: AppColors.colors['primary'],
                            );
                          },
                        )
                      : Icon(
                          Icons.image_not_supported,
                          color: AppColors.colors['primary'],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'Unnamed Product',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 0),
                    Text(
                      '\$${product['price']?.toString() ?? '0'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.colors['accent2'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.add_shopping_cart,
                          label: 'Cart',
                          onPressed: () => _addToCart(product['id']),
                        ),
                        _buildActionButton(
                          icon: Icons.shopping_bag,
                          label: 'Buy',
                          onPressed: () => _processDummyPayment(
                            double.parse(product['price'].toString()),
                          ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.colors['accent2']!,
            AppColors.colors['accent1']!,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 10),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          const SizedBox(height: 16),
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
        final orderItems = order['order_items'] ?? [];
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
                    Text(
                        'Delivery Date: ${DateTime.parse(order['delivery_date']).toString().substring(0, 16)}'),
                    Text('Shipping Address: ${order['address']}'),
                    const Divider(),
                    const Text(
                      'Items:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...order['order_items'].map<Widget>((item) {
                      final product = item['products'];
                      if (product == null) {
                        return const ListTile(
                          title: Text('Product not found'),
                          subtitle: Text('This product may have been removed'),
                        );
                      }
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.network(
                        product['image_url'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          color: AppColors.colors['primary'],
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('\$${product['price']} x ${item['quantity']}'),
                  trailing: SizedBox(
                    width: 120, // Fixed width for the trailing section
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            maxWidth: 30,
                          ),
                          padding: EdgeInsets.zero,
                          icon:
                              const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () => _updateCartItemQuantity(
                            item['id'],
                            item['quantity'] - 1,
                          ),
                        ),
                        Text(
                          '${item['quantity']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            maxWidth: 30,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => _updateCartItemQuantity(
                            item['id'],
                            item['quantity'] + 1,
                          ),
                        ),
                      ],
                    ),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.colors['accent2'],
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
  Future<void> _updateCartItemQuantity(
      String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        // Remove item if quantity is 0 or less
        await supabase.from('cart').delete().eq('id', cartItemId);
      } else {
        // Update quantity
        await supabase
            .from('cart')
            .update({'quantity': newQuantity}).eq('id', cartItemId);
      }
      await _fetchCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update cart')),
      );
    }
  }
}
