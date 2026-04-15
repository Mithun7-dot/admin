import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('*, categories(name)')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) {
      final name = (p['name'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'Products',
              subtitle: '${_products.length} total items',
              action: ElevatedButton.icon(
                onPressed: () => _showProductDialog(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text('ADD PRODUCT'),
              ),
            ),
            const SizedBox(height: 24),
            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: TextField(
                style: const TextStyle(
                    fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search by product name...',
                  prefixIcon: Icon(Icons.search_outlined,
                      size: 18, color: AdminColors.textMuted),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: _loading
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: AdminColors.accent)))
                  : LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth > 800) return _buildTable();
                      return _buildCardList();
                    }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final products = _filtered;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 800),
        child: Container(
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  _h('PRODUCT', 3),
                  _h('CATEGORY', 2),
                  _h('PRICE', 1),
                  _h('STOCK', 1),
                  _h('STATUS', 1),
                  _h('ACTIONS', 2),
                ]),
              ),
              const Divider(height: 1, color: AdminColors.border),
              if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                      child: Text(
                          _searchQuery.isEmpty
                              ? 'No products yet.'
                              : 'No results for "$_searchQuery".',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: AdminColors.textMuted))),
                ),
              ...products.asMap().entries.map((e) {
                final p = e.value;
                final cat = p['categories'] as Map<String, dynamic>?;
                final images = (p['images'] as List?)?.cast<String>() ?? [];
                final stock = p['stock_quantity'] as int? ?? 0;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Row(children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: AdminColors.surface,
                                    border:
                                        Border.all(color: AdminColors.border),
                                  ),
                                  child: images.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(images.first,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      size: 18,
                                                      color: AdminColors
                                                          .textMuted)))
                                      : const Icon(Icons.image_outlined,
                                          size: 18,
                                          color: AdminColors.textMuted),
                                ),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(p['name'] as String,
                                          style: const TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
                                          overflow: TextOverflow.ellipsis),
                                      if ((p['credit_value'] as num? ?? 0) > 0)
                                        Text('${p['credit_value']} credits',
                                            style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 10,
                                                color: AdminColors.accent)),
                                    ])),
                              ])),
                          Expanded(
                              flex: 2,
                              child: Text(cat?['name'] as String? ?? '—',
                                  style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      color: AdminColors.textSecondary))),
                          Expanded(
                              flex: 1,
                              child: Text('₹${p['price']}',
                                  style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white))),
                          Expanded(
                              flex: 1,
                              child: Text('$stock',
                                  style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      color: stock < 5
                                          ? AdminColors.error
                                          : AdminColors.textSecondary))),
                          Expanded(
                              flex: 1,
                              child: _Toggle(
                                value: p['is_active'] as bool? ?? false,
                                onChanged: (v) => _toggleActive(p['id'], v),
                              )),
                          Expanded(
                              flex: 2,
                              child: Row(children: [
                                _iconBtn(
                                    Icons.edit_outlined,
                                    AdminColors.textMuted,
                                    () => _showProductDialog(context,
                                        product: p)),
                                const SizedBox(width: 8),
                                _iconBtn(Icons.delete_outline,
                                    AdminColors.error, () => _delete(p['id'])),
                              ])),
                        ],
                      ),
                    ),
                    if (e.key < products.length - 1)
                      const Divider(height: 1, color: AdminColors.border),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardList() {
    final products = _filtered;
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
            child: Text(
                _searchQuery.isEmpty
                    ? 'No products yet.'
                    : 'No results for "$_searchQuery".',
                style: const TextStyle(
                    fontFamily: 'Manrope', color: AdminColors.textMuted))),
      );
    }
    return Column(
      children: products.map((p) {
        final cat = p['categories'] as Map<String, dynamic>?;
        final images = (p['images'] as List?)?.cast<String>() ?? [];
        final stock = p['stock_quantity'] as int? ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 56,
                height: 64,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AdminColors.border),
                ),
                child: images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(images.first, fit: BoxFit.cover))
                    : const Icon(Icons.image_outlined,
                        size: 20, color: AdminColors.textMuted),
              ),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] as String,
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  if (cat != null)
                    Text(cat['name'] as String,
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: AdminColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('₹${p['price']} | Stock: $stock',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: stock < 5
                              ? AdminColors.error
                              : AdminColors.textSecondary)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    ActionChip(
                      label: const Text('Edit Product',
                          style: TextStyle(fontSize: 10)),
                      onPressed: () => _showProductDialog(context, product: p),
                      backgroundColor: AdminColors.surfaceHigh,
                      side: const BorderSide(color: AdminColors.border),
                    ),
                    ActionChip(
                      label: const Text('Manage Sizes / Stock',
                          style: TextStyle(fontSize: 10)),
                      onPressed: () => _showVariantsDialog(context, p),
                      backgroundColor: AdminColors.surfaceHigh,
                      side: const BorderSide(color: AdminColors.border),
                    ),
                    ActionChip(
                      label: const Text('Delete',
                          style: TextStyle(
                              fontSize: 10, color: AdminColors.error)),
                      onPressed: () => _delete(p['id']),
                      backgroundColor: AdminColors.surfaceHigh,
                      side: const BorderSide(color: AdminColors.error),
                    ),
                  ]),
                ],
              )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _h(String t, int flex) => Expanded(
      flex: flex,
      child: Text(t,
          style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.textMuted)));

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 16)));

  Future<void> _toggleActive(String id, bool value) async {
    await Supabase.instance.client
        .from('products')
        .update({'is_active': value}).eq('id', id);
    _load();
  }

  Future<void> _delete(String id) async {
    // Check for order references first
    final orderRefs = await Supabase.instance.client
        .from('order_items')
        .select('id')
        .eq('product_id', id)
        .limit(1);

    final hasOrders = orderRefs.isNotEmpty;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AdminColors.border)),
        title: Text(
            hasOrders ? 'Deactivate or Force Delete Product' : 'Delete Product',
            style: const TextStyle(
                fontFamily: 'Epilogue',
                color: Colors.white,
                fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                hasOrders
                    ? 'This product has existing orders. Choose an action:'
                    : 'Are you sure you want to delete this product?',
                style: const TextStyle(
                    fontFamily: 'Manrope', color: AdminColors.textSecondary)),
            if (hasOrders) ...[
              const SizedBox(height: 16),
              const Text(
                  '• Deactivate: Removes from catalog but preserves order history',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AdminColors.textMuted)),
              const SizedBox(height: 4),
              const Text(
                  '• Force Delete: Permanently deletes product AND related order items',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AdminColors.error)),
            ] else
              const Text('This action cannot be undone.',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AdminColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('CANCEL')),
          if (hasOrders) ...[
            ElevatedButton(
                onPressed: () =>
                    Navigator.pop(dialogCtx, true), // true = deactivate
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.warning),
                child: const Text('DEACTIVATE',
                    style: TextStyle(color: Colors.black))),
            const SizedBox(width: 8),
            ElevatedButton(
                onPressed: () =>
                    Navigator.pop(dialogCtx, null), // null = force delete
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.error),
                child: const Text('FORCE DELETE',
                    style: TextStyle(color: Colors.white))),
          ] else
            ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.error),
                child: const Text('DELETE',
                    style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == false || !mounted)
      return; // User cancelled or widget unmounted

    try {
      if (hasOrders && confirm == null) {
        // Force delete - also delete order items
        await Supabase.instance.client
            .from('order_items')
            .delete()
            .eq('product_id', id);
        await Supabase.instance.client.from('products').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: AdminColors.error,
              content: Text(
                  'Product and related order items permanently deleted.',
                  style:
                      TextStyle(fontFamily: 'Manrope', color: Colors.white))));
        }
      } else if (hasOrders) {
        // Deactivate
        await Supabase.instance.client
            .from('products')
            .update({'is_active': false}).eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: AdminColors.warning,
              content: Text('Product deactivated. Order history preserved.',
                  style:
                      TextStyle(fontFamily: 'Manrope', color: Colors.black))));
        }
      } else {
        // Normal delete
        await Supabase.instance.client.from('products').delete().eq('id', id);
      }
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AdminColors.error.withValues(alpha: 0.9),
            content: Text('Delete failed: $e',
                style: const TextStyle(
                    fontFamily: 'Manrope', color: Colors.white))));
      }
    }
  }

  void _showProductDialog(BuildContext context,
      {Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(product: product, onSaved: _load),
    );
  }

  void _showVariantsDialog(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => _VariantsDialog(
        product: product,
        onSaved: _load,
        autoRemoveOnZeroStock:
            product['auto_remove_on_zero_stock'] as bool? ?? false,
      ),
    );
  }
}

class _VariantsDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onSaved;
  final bool autoRemoveOnZeroStock;
  const _VariantsDialog({
    required this.product,
    required this.onSaved,
    required this.autoRemoveOnZeroStock,
  });
  @override
  State<_VariantsDialog> createState() => _VariantsDialogState();
}

class _VariantsDialogState extends State<_VariantsDialog> {
  static const _sizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

  List<Map<String, dynamic>> _variants = [];
  bool _loading = true;
  final Map<String, TextEditingController> _stockControllers = {};
  final Map<String, String> _selectedSizes = {};
  final Map<String, bool> _savingVariants = {};
  late Map<String, dynamic> _currentProduct; // Track current product state
  bool _autoRemoveOnZeroStock = false;
  bool _savingAutoRemove = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = Map<String, dynamic>.from(widget.product);
    _autoRemoveOnZeroStock = widget.autoRemoveOnZeroStock;
    _loadVariants();
  }

  @override
  void dispose() {
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setVariantControllers(List<Map<String, dynamic>> variants) {
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    _stockControllers.clear();
    _selectedSizes.clear();

    for (final variant in variants) {
      final id = variant['id'] as String;
      _stockControllers[id] = TextEditingController(
          text: variant['stock_quantity']?.toString() ?? '0');
      _selectedSizes[id] = variant['size'] as String? ?? 'S';
    }
  }

  Future<void> _loadVariants() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('product_variants')
          .select()
          .eq('product_id', widget.product['id'])
          .order('created_at');

      // Also fetch current product state
      final productData = await Supabase.instance.client
          .from('products')
          .select()
          .eq('id', widget.product['id'])
          .single();

      if (mounted) {
        setState(() {
          _variants = List<Map<String, dynamic>>.from(data);
          _currentProduct = Map<String, dynamic>.from(productData);
          _setVariantControllers(_variants);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _nextAvailableSize() {
    final usedSizes = _variants
        .map((variant) => variant['size'] as String? ?? '')
        .where((size) => size.isNotEmpty)
        .toSet();
    return _sizeOptions.firstWhere((size) => !usedSizes.contains(size),
        orElse: () => 'S');
  }

  Future<void> _addVariant() async {
    try {
      await Supabase.instance.client.from('product_variants').insert({
        'product_id': widget.product['id'],
        'size': _nextAvailableSize(),
        'stock_quantity': 0,
      });
      await _loadVariants();
      // Recalculate total stock after adding
      final totalStock = _variants.fold<int>(
          0, (sum, v) => sum + (v['stock_quantity'] as int? ?? 0));
      await Supabase.instance.client.from('products').update(
          {'stock_quantity': totalStock}).eq('id', widget.product['id']);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AdminColors.error,
            content: Text(
              'Failed to add size: $e',
              style:
                  const TextStyle(fontFamily: 'Manrope', color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveVariant(String vId) async {
    final size = _selectedSizes[vId] ?? 'S';
    final stock = int.tryParse(_stockControllers[vId]?.text ?? '') ?? 0;
    await _updateVariant(vId, size, stock);
  }

  Future<void> _updateVariant(String vId, String size, int stock) async {
    if (!mounted) return;
    setState(() => _savingVariants[vId] = true);

    try {
      await Supabase.instance.client.from('product_variants').update({
        'size': size,
        'stock_quantity': stock,
      }).eq('id', vId);

      // Recalculate total stock from all variants
      final totalStock = _variants.fold<int>(0, (sum, v) {
        if (v['id'] == vId) {
          return sum + stock; // Use the new stock for this variant
        }
        return sum + (v['stock_quantity'] as int? ?? 0);
      });

      // Update product stock_quantity
      await Supabase.instance.client.from('products').update(
          {'stock_quantity': totalStock}).eq('id', widget.product['id']);

      // Check auto-deactivate using CURRENT product state
      final autoRemove = _autoRemoveOnZeroStock;
      final isActive = _currentProduct['is_active'] as bool? ?? true;

      if (autoRemove && totalStock == 0 && isActive) {
        await Supabase.instance.client
            .from('products')
            .update({'is_active': false}).eq('id', widget.product['id']);
      } else if (autoRemove && totalStock > 0 && !isActive) {
        await Supabase.instance.client
            .from('products')
            .update({'is_active': true}).eq('id', widget.product['id']);
      }

      await _loadVariants();
      widget.onSaved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AdminColors.success,
            duration: Duration(seconds: 2),
            content: Text(
              'Stock updated successfully',
              style: TextStyle(fontFamily: 'Manrope', color: Colors.black),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AdminColors.error,
            content: Text(
              'Failed to update stock: $e',
              style:
                  const TextStyle(fontFamily: 'Manrope', color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingVariants[vId] = false);
    }
  }

  Future<void> _updateAutoRemoveSetting(bool newValue) async {
    if (!mounted) return;
    setState(() => _savingAutoRemove = true);

    try {
      await Supabase.instance.client
          .from('products')
          .update({'auto_remove_on_zero_stock': newValue}).eq(
              'id', widget.product['id']);

      setState(() {
        _autoRemoveOnZeroStock = newValue;
        _currentProduct['auto_remove_on_zero_stock'] = newValue;
      });

      widget.onSaved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AdminColors.success,
            duration: const Duration(seconds: 2),
            content: Text(
              newValue ? 'Auto-deactivate ENABLED' : 'Auto-deactivate DISABLED',
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: Colors.black,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AdminColors.error,
            content: Text(
              'Failed to update setting: $e',
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAutoRemove = false);
    }
  }

  Future<void> _deleteVariant(String vId) async {
    try {
      await Supabase.instance.client
          .from('product_variants')
          .delete()
          .eq('id', vId);
      await _loadVariants();
      // Recalculate total stock after deleting
      final totalStock = _variants.fold<int>(
          0, (sum, v) => sum + (v['stock_quantity'] as int? ?? 0));
      await Supabase.instance.client.from('products').update(
          {'stock_quantity': totalStock}).eq('id', widget.product['id']);

      // Check auto-deactivate after deletion using CURRENT product state
      final isActive = _currentProduct['is_active'] as bool? ?? true;

      if (_autoRemoveOnZeroStock && totalStock == 0 && isActive) {
        await Supabase.instance.client
            .from('products')
            .update({'is_active': false}).eq('id', widget.product['id']);
      }

      widget.onSaved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AdminColors.success,
            duration: Duration(seconds: 2),
            content: Text(
              'Size deleted successfully',
              style: TextStyle(fontFamily: 'Manrope', color: Colors.black),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AdminColors.error,
            content: Text(
              'Failed to delete size: $e',
              style:
                  const TextStyle(fontFamily: 'Manrope', color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Sizes & Stock (${widget.product['name']})',
                      style: const TextStyle(
                          fontFamily: 'Epilogue',
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Auto-deactivate toggle
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _autoRemoveOnZeroStock
                            ? AdminColors.warning
                            : AdminColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Auto-Deactivate at 0 Stock',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _autoRemoveOnZeroStock
                                    ? 'Product will auto-deactivate when stock reaches 0'
                                    : 'Manual control over product status',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  color: AdminColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _savingAutoRemove
                            ? const SizedBox(
                                width: 40,
                                height: 24,
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AdminColors.accent,
                                    ),
                                  ),
                                ),
                              )
                            : Switch(
                                value: _autoRemoveOnZeroStock,
                                onChanged: _updateAutoRemoveSetting,
                                activeThumbColor: AdminColors.success,
                                activeTrackColor:
                                    AdminColors.warning.withValues(alpha: 0.3),
                                inactiveThumbColor: AdminColors.textMuted,
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (_variants.isEmpty)
                      const Text('No sizes added yet.',
                          style: TextStyle(color: AdminColors.textMuted)),
                    ..._variants.map((v) {
                      final variantId = v['id'] as String;
                      final currentSize = _selectedSizes[variantId] ??
                          (v['size'] as String? ?? 'S');
                      final usedSizes = _variants
                          .map((variant) => variant['size'] as String? ?? '')
                          .where((size) => size.isNotEmpty)
                          .toSet();
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: currentSize,
                                  dropdownColor: AdminColors.surfaceHigh,
                                  decoration:
                                      const InputDecoration(labelText: 'Size'),
                                  style: const TextStyle(color: Colors.white),
                                  items: _sizeOptions.map((size) {
                                    final isUsed = usedSizes.contains(size) &&
                                        size != currentSize;
                                    return DropdownMenuItem(
                                      value: size,
                                      enabled: !isUsed,
                                      child: Text(size),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedSizes[variantId] = value;
                                    });
                                    _saveVariant(variantId);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            _stockControllers[variantId],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Stock'),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        onSubmitted: (_) =>
                                            _saveVariant(variantId),
                                      ),
                                    ),
                                    IconButton(
                                      icon: _savingVariants[variantId] ?? false
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AdminColors.accent,
                                              ),
                                            )
                                          : const Icon(Icons.save,
                                              color: AdminColors.accent),
                                      tooltip: 'Save variant',
                                      onPressed:
                                          (_savingVariants[variantId] ?? false)
                                              ? null
                                              : () => _saveVariant(variantId),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AdminColors.error),
                                onPressed: () => _deleteVariant(variantId),
                              )
                            ],
                          ));
                    }),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add),
                      label: const Text('ADD SIZE'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('DONE')),
                  )
                ])));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Dialog with dual image input (local upload + URL)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSaved;
  const _ProductDialog({this.product, required this.onSaved});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _name,
      _price,
      _comparePrice,
      _stock,
      _desc,
      _creditValue;
  final TextEditingController _urlInput = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCatId;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _loading = false;
  bool _uploadingImage = false;

  /// List of image URLs (from storage or external links)
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?['name'] ?? '');
    _price = TextEditingController(text: p?['price']?.toString() ?? '');
    _comparePrice =
        TextEditingController(text: p?['compare_price']?.toString() ?? '');
    _stock =
        TextEditingController(text: p?['stock_quantity']?.toString() ?? '');
    _desc = TextEditingController(text: p?['description'] ?? '');
    _creditValue =
        TextEditingController(text: p?['credit_value']?.toString() ?? '0');
    _isActive = p?['is_active'] ?? true;
    _isFeatured = p?['is_featured'] ?? false;
    _selectedCatId = p?['category_id'];
    _imageUrls = List<String>.from(p?['images'] ?? []);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await Supabase.instance.client
        .from('categories')
        .select()
        .eq('is_active', true);
    // Ensure unique categories by ID to prevent dropdown assertion errors
    final uniqueData = <String, Map<String, dynamic>>{};
    for (final cat in data) {
      uniqueData[cat['id'] as String] = cat;
    }
    final categories = uniqueData.values.toList();
    // If selected category is not in active categories, reset it
    if (_selectedCatId != null &&
        !categories.any((c) => c['id'] == _selectedCatId)) {
      _selectedCatId = null;
    }
    setState(() => _categories = categories);
  }

  // ── Local file upload ──────────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _uploadingImage = true);
    try {
      final ext = file.extension ?? 'jpg';
      final path = 'products/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage.from('products').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
          );
      final publicUrl =
          Supabase.instance.client.storage.from('products').getPublicUrl(path);
      setState(() => _imageUrls.add(publicUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Upload failed: $e',
                style: const TextStyle(fontFamily: 'Manrope'))));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ── Add via URL ────────────────────────────────────────────────────────────
  void _addImageUrl() {
    final url = _urlInput.text.trim();
    if (url.isEmpty) return;
    if (!(Uri.tryParse(url)?.isAbsolute ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid URL',
              style: TextStyle(fontFamily: 'Manrope'))));
      return;
    }
    setState(() {
      _imageUrls.add(url);
      _urlInput.clear();
    });
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      // Clean slug generation - remove invalid chars and normalize hyphens
      final slug = _name.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // keep spaces and hyphens
          .replaceAll(RegExp(r'\s+'), '-') // replace spaces with single hyphen
          .replaceAll(
              RegExp(r'-+'), '-') // replace multiple hyphens with single
          .replaceAll(RegExp(r'^-|-$'), ''); // remove leading/trailing hyphens

      final stockQty = widget.product != null
          ? widget.product!['stock_quantity'] as int? ?? 0
          : int.tryParse(_stock.text) ?? 0;
      // Auto-remove: handled in variants now
      final isActive = _isActive;

      // Generate unique slug with random component to avoid duplicates
      final uniqueSuffix = Random().nextInt(999999).toString().padLeft(6, '0');
      final finalSlug = widget.product != null
          ? widget.product!['slug'] // preserve existing slug on edit
          : slug.isEmpty
              ? 'product-$uniqueSuffix-${DateTime.now().millisecondsSinceEpoch}'
              : '$slug-$uniqueSuffix-${DateTime.now().millisecondsSinceEpoch}';

      final data = {
        'name': _name.text.trim(),
        'slug': finalSlug,
        'description': _desc.text.trim(),
        'price': double.tryParse(_price.text) ?? 0.0,
        'compare_price': _comparePrice.text.isNotEmpty
            ? double.tryParse(_comparePrice.text)
            : null,
        'stock_quantity': stockQty,
        'category_id': _selectedCatId,
        'is_active': isActive,
        'is_featured': _isFeatured,
        'images': _imageUrls,
        'credit_value': int.tryParse(_creditValue.text) ?? 0,
      };
      if (widget.product != null) {
        await Supabase.instance.client
            .from('products')
            .update(data)
            .eq('id', widget.product!['id']);
      } else {
        await Supabase.instance.client.from('products').insert(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AdminColors.error.withValues(alpha: 0.9),
            content: Text('Error: $e',
                style: const TextStyle(
                    fontFamily: 'Manrope', color: Colors.white))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 640,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        widget.product == null ? 'Add Product' : 'Edit Product',
                        style: const TextStyle(
                            fontFamily: 'Epilogue',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _tf(_name, 'Product Name *'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child:
                        _tf(_price, 'Price (₹) *', type: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                    child: _tf(_comparePrice, 'Compare Price (₹)',
                        type: TextInputType.number)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _tf(_stock, 'Stock Quantity',
                        type: TextInputType.number,
                        readOnly: widget.product != null)),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // placeholder
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _tf(_creditValue, 'Credit Value (pts)',
                        type: TextInputType.number)),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // placeholder
              ]),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCatId,
                dropdownColor: AdminColors.surfaceHigh,
                decoration: const InputDecoration(labelText: 'Category'),
                style: const TextStyle(
                    fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
                items: _categories
                    .map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['name'] as String)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCatId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _desc,
                maxLines: 3,
                style: const TextStyle(
                    fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                    labelText: 'Description', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),

              // ── Image Section ─────────────────────────────────────────────
              _ImageSection(
                imageUrls: _imageUrls,
                urlController: _urlInput,
                uploadingImage: _uploadingImage,
                onPickFile: _pickAndUploadImage,
                onAddUrl: _addImageUrl,
                onRemove: _removeImage,
              ),

              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: CheckboxListTile(
                  title: const Text('Active',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: 12)),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v!),
                  activeColor: AdminColors.accent,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
                Expanded(
                    child: CheckboxListTile(
                  title: const Text('Featured',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: 12)),
                  value: _isFeatured,
                  onChanged: (v) => setState(() => _isFeatured = v!),
                  activeColor: AdminColors.accent,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
              ]),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text(widget.product == null
                            ? 'ADD PRODUCT'
                            : 'SAVE CHANGES'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label,
          {TextInputType? type, bool readOnly = false}) =>
      TextField(
          controller: c,
          keyboardType: type,
          readOnly: readOnly,
          style: const TextStyle(
              fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
          decoration: InputDecoration(labelText: label));

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _comparePrice.dispose();
    _stock.dispose();
    _desc.dispose();
    _urlInput.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Section Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ImageSection extends StatelessWidget {
  final List<String> imageUrls;
  final TextEditingController urlController;
  final bool uploadingImage;
  final VoidCallback onPickFile;
  final VoidCallback onAddUrl;
  final void Function(int) onRemove;

  const _ImageSection({
    required this.imageUrls,
    required this.urlController,
    required this.uploadingImage,
    required this.onPickFile,
    required this.onAddUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Images',
            style: TextStyle(
                fontFamily: 'Epilogue',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),

        // ── Dual input row ────────────────────────────────────────────────
        Row(
          children: [
            // Upload from device button
            _UploadButton(loading: uploadingImage, onTap: onPickFile),
            const SizedBox(width: 12),
            const Text('or',
                style: TextStyle(
                    fontFamily: 'Manrope',
                    color: AdminColors.textMuted,
                    fontSize: 12)),
            const SizedBox(width: 12),
            // URL input
            Expanded(
              child: TextField(
                controller: urlController,
                style: const TextStyle(
                    fontFamily: 'Manrope', color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Paste image URL...',
                  hintStyle: const TextStyle(
                      color: AdminColors.textMuted, fontSize: 12),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AdminColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AdminColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AdminColors.accent),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AdminColors.accent, size: 18),
                    tooltip: 'Add URL',
                    onPressed: onAddUrl,
                  ),
                ),
                onSubmitted: (_) => onAddUrl(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Image previews ──────────────────────────────────────────────
        if (imageUrls.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: imageUrls.asMap().entries.map((e) {
              return _ImageTile(url: e.value, index: e.key, onRemove: onRemove);
            }).toList(),
          ),
        ] else
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AdminColors.border, style: BorderStyle.solid),
            ),
            child: const Center(
              child: Text('No images yet — upload or paste a URL above',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AdminColors.textMuted)),
            ),
          ),
      ],
    );
  }
}

class _UploadButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _UploadButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.accent.withOpacity(0.5)),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AdminColors.accent))
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file_outlined,
                      color: AdminColors.accent, size: 16),
                  SizedBox(width: 6),
                  Text('Upload File',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AdminColors.accent,
                          fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final int index;
  final void Function(int) onRemove;
  const _ImageTile(
      {required this.url, required this.index, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminColors.border),
            color: AdminColors.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AdminColors.textMuted, size: 28)),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AdminColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AdminColors.accent.withOpacity(0.85),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('MAIN',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.black)),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle
// ─────────────────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AdminColors.success,
      inactiveThumbColor: AdminColors.textMuted,
    );
  }
}
