// ─────────────────────────────────────────────────────────────────────────────
// coupons_screen.dart — Discount coupon management (responsive)
// Route: /coupons
//
// Features:
//   • Lists all coupons in a table (desktop) or cards (mobile)
//   • Two discount types:
//       - 'percentage' — e.g. 20% off (capped by max_discount if set)
//       - 'flat'       — e.g. ₹100 off
//   • Toggle active/inactive per coupon (Switch)
//   • Add / Edit via _CouponDialog
//   • Delete coupon
//   • usage_limit: max number of times the coupon can be used (null = unlimited)
//   • used_count: tracks how many times it has been applied
//
// Supabase table: coupons
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches all coupons, newest first.
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('coupons')
        .select()
        .order('created_at', ascending: false);
    if (mounted) {
      setState(() {
        _coupons = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  /// Instantly patches is_active without opening a dialog.
  Future<void> _toggle(String id, bool val) async {
    await Supabase.instance.client
        .from('coupons')
        .update({'is_active': val}).eq('id', id);
    if (mounted) _load();
  }

  /// Deletes a coupon by ID.
  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.card,
        title:
            const Text('Delete Coupon', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this coupon?',
            style: TextStyle(color: AdminColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('coupons').delete().eq('id', id);
      if (mounted) await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminPageHeader(
            title: 'Coupons',
            subtitle: '${_coupons.length} discount codes',
            action: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.black),
              label: const Text('ADD COUPON'),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AdminColors.accent))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) return _buildTable();
                      return _buildCardList();
                    },
                  ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ── Desktop Table ──────────────────────────────────────────────────────────
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.border)),
      child: Column(children: [
        // Table header
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              _h('CODE', 2),
              _h('TYPE', 2),
              _h('VALUE', 1),
              _h('MIN ORDER', 2),
              _h('USAGE', 1),
              _h('STATUS', 1),
              _h('ACTIONS', 2),
            ])),
        const Divider(height: 1, color: AdminColors.border),

        if (_coupons.isEmpty)
          const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                  child: Text('No coupons yet.',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AdminColors.textMuted)))),

        // One row per coupon
        ..._coupons.asMap().entries.map((e) {
          final c = e.value;
          final isPercent = c['discount_type'] == 'percentage';

          return Column(children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(children: [
                  // ── Coupon code (styled like a ticket tag) ─────────────────────
                  Expanded(
                      flex: 2,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AdminColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AdminColors.border)),
                          child: Text(c['code'] as String,
                              style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1)))),

                  // ── Discount type badge (PERCENTAGE or FLAT) ───────────────────
                  Expanded(
                      flex: 2,
                      child: Row(children: [
                        const SizedBox(width: 12),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            color: isPercent
                                ? AdminColors.info.withOpacity(0.1)
                                : AdminColors.success.withOpacity(0.1),
                            child: Text(isPercent ? 'PERCENTAGE' : 'FLAT',
                                style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w800,
                                    color: isPercent
                                        ? AdminColors.info
                                        : AdminColors.success))),
                      ])),

                  // ── Value (e.g. 20% or ₹100) ───────────────────────────────────
                  Expanded(
                      flex: 1,
                      child: Text(
                          isPercent
                              ? '${c['discount_value']}%'
                              : '₹${c['discount_value']}',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))),

                  Expanded(
                      flex: 2,
                      child: Text('₹${c['min_order_amount']}',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: AdminColors.textSecondary))),

                  Expanded(
                      flex: 1,
                      child: Text(
                          '${c['used_count']}/${c['usage_limit'] ?? '∞'}',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: AdminColors.textSecondary))),

                  Expanded(
                      flex: 1,
                      child: Switch(
                          value: c['is_active'] as bool? ?? false,
                          onChanged: (v) => _toggle(c['id'], v),
                          activeThumbColor: AdminColors.success)),

                  Expanded(
                      flex: 2,
                      child: Row(children: [
                        InkWell(
                            onTap: () => _showDialog(context, coupon: c),
                            child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.edit_outlined,
                                    color: AdminColors.textMuted, size: 16))),
                        const SizedBox(width: 4),
                        InkWell(
                            onTap: () => _delete(c['id']),
                            child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.delete_outline,
                                    color: AdminColors.error, size: 16))),
                      ])),
                ])),
            if (e.key < _coupons.length - 1)
              const Divider(height: 1, color: AdminColors.border),
          ]);
        }),
      ]),
    );
  }

  // ── Mobile Card List ────────────────────────────────────────────────────────
  Widget _buildCardList() {
    if (_coupons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
            child: Text('No coupons yet.',
                style: TextStyle(
                    fontFamily: 'Manrope', color: AdminColors.textMuted))),
      );
    }
    return Column(
      children: _coupons.map((c) {
        final isPercent = c['discount_type'] == 'percentage';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code + type badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AdminColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AdminColors.border)),
                    child: Text(c['code'] as String,
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPercent
                          ? AdminColors.info.withOpacity(0.1)
                          : AdminColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isPercent ? 'PERCENTAGE' : 'FLAT',
                        style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                            color: isPercent
                                ? AdminColors.info
                                : AdminColors.success)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Value + min order
              Row(
                children: [
                  Text(
                      isPercent
                          ? '${c['discount_value']}% off'
                          : '₹${c['discount_value']} off',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(width: 16),
                  Text('Min: ₹${c['min_order_amount']}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: AdminColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              // Usage + active toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Used: ${c['used_count']}/${c['usage_limit'] ?? '∞'}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: AdminColors.textSecondary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c['is_active'] == true ? 'Active' : 'Inactive',
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              color: c['is_active'] == true
                                  ? AdminColors.success
                                  : AdminColors.textMuted)),
                      Switch(
                        value: c['is_active'] as bool? ?? false,
                        onChanged: (v) => _toggle(c['id'], v),
                        activeThumbColor: AdminColors.success,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDialog(context, coupon: c),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(c['id']),
                      icon: const Icon(Icons.delete_outline,
                          size: 14, color: AdminColors.error),
                      label: const Text('Delete',
                          style: TextStyle(
                              fontSize: 11, color: AdminColors.error)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: AdminColors.error),
                      ),
                    ),
                  ),
                ],
              ),
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

  void _showDialog(BuildContext context, {Map<String, dynamic>? coupon}) {
    showDialog(
        context: context,
        builder: (_) => _CouponDialog(coupon: coupon, onSaved: _load));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coupon Add/Edit Dialog (responsive)
// ─────────────────────────────────────────────────────────────────────────────
class _CouponDialog extends StatefulWidget {
  final Map<String, dynamic>? coupon; // null = add, non-null = edit
  final Future<void> Function() onSaved;
  const _CouponDialog({this.coupon, required this.onSaved});
  @override
  State<_CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<_CouponDialog> {
  late final TextEditingController _code,
      _desc,
      _value,
      _minOrder,
      _maxDiscount,
      _limit;
  String _type = 'percentage'; // Selected discount type: 'percentage' or 'flat'
  bool _active = true, _loading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _code = TextEditingController(text: c?['code'] ?? '');
    _desc = TextEditingController(text: c?['description'] ?? '');
    _value =
        TextEditingController(text: c?['discount_value']?.toString() ?? '');
    _minOrder =
        TextEditingController(text: c?['min_order_amount']?.toString() ?? '0');
    _maxDiscount =
        TextEditingController(text: c?['max_discount']?.toString() ?? '');
    _limit = TextEditingController(text: c?['usage_limit']?.toString() ?? '');
    _type = c?['discount_type'] ?? 'percentage';
    _active = c?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _desc.dispose();
    _value.dispose();
    _minOrder.dispose();
    _maxDiscount.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final data = {
        'code': _code.text.trim().toUpperCase(),
        'discount_type': _type,
        'discount_value': double.tryParse(_value.text) ?? 0,
        'min_order_amount': double.tryParse(_minOrder.text) ?? 0,
        'max_discount': _maxDiscount.text.isNotEmpty
            ? double.tryParse(_maxDiscount.text)
            : null,
        'is_active': _active,
      };

      if (widget.coupon != null) {
        await Supabase.instance.client
            .from('coupons')
            .update(data)
            .eq('id', widget.coupon!['id']);
      } else {
        await Supabase.instance.client.from('coupons').insert(data);
      }

      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e',
                style: const TextStyle(fontFamily: 'Manrope'))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dialogWidth = w < 560 ? w * 0.92 : 500.0;
    final isMobile = w < 560;

    return Dialog(
        child: Container(
            width: dialogWidth,
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(widget.coupon == null ? 'Add Coupon' : 'Edit Coupon',
                      style: const TextStyle(
                          fontFamily: 'Epilogue',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 24),

                  _tf(_code, 'Coupon Code *'),
                  const SizedBox(height: 16),
                  _tf(_desc, 'Description'),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    dropdownColor: AdminColors.surfaceHigh,
                    decoration:
                        const InputDecoration(labelText: 'Discount Type'),
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontSize: 13),
                    items: const [
                      DropdownMenuItem(
                          value: 'percentage', child: Text('Percentage (%)')),
                      DropdownMenuItem(
                          value: 'fixed', child: Text('Flat Amount (₹)')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 16),

                  // Responsive: stack on mobile, row on desktop
                  if (isMobile) ...[
                    _tf(_value, 'Discount Value *', type: TextInputType.number),
                    const SizedBox(height: 16),
                    _tf(_minOrder, 'Min Order (₹)', type: TextInputType.number),
                  ] else
                    Row(children: [
                      Expanded(
                          child: _tf(_value, 'Discount Value *',
                              type: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _tf(_minOrder, 'Min Order (₹)',
                              type: TextInputType.number)),
                    ]),
                  const SizedBox(height: 16),

                  if (isMobile) ...[
                    _tf(_maxDiscount, 'Max Discount (₹)',
                        type: TextInputType.number),
                    const SizedBox(height: 16),
                    _tf(_limit, 'Usage Limit', type: TextInputType.number),
                  ] else
                    Row(children: [
                      Expanded(
                          child: _tf(_maxDiscount, 'Max Discount (₹)',
                              type: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _tf(_limit, 'Usage Limit',
                              type: TextInputType.number)),
                    ]),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                      title: const Text('Active',
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              color: Colors.white,
                              fontSize: 13)),
                      value: _active,
                      onChanged: (v) => setState(() => _active = v!),
                      activeColor: AdminColors.accent,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading),
                  const SizedBox(height: 24),

                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                            : Text(widget.coupon == null
                                ? 'CREATE COUPON'
                                : 'SAVE')),
                  ]),
                ]))));
  }

  Widget _tf(TextEditingController c, String label, {TextInputType? type}) =>
      TextField(
          controller: c,
          keyboardType: type,
          style: const TextStyle(
              fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
          decoration: InputDecoration(labelText: label));
}
