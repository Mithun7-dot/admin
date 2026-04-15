// ─────────────────────────────────────────────────────────────────────────────
// featured_strips_screen.dart — Discover strip management
// Route: /discover
//
// "Discover" strips are the horizontal scrolling image cards shown just below
// the hero banner on the consumer app's home screen. Each card has:
//   • Full-bleed image (upload or paste URL)
//   • Title text (optional)
//   • CTA button label (e.g. "DISCOVER NOW")
//   • Tap action URL (navigate to search, category, etc.)
//   • Sort order
//   • Active toggle
//
// Supabase table: featured_strips
// ─────────────────────────────────────────────────────────────────────────────

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

class FeaturedStripsScreen extends StatefulWidget {
  const FeaturedStripsScreen({super.key});
  @override
  State<FeaturedStripsScreen> createState() => _FeaturedStripsScreenState();
}

class _FeaturedStripsScreenState extends State<FeaturedStripsScreen> {
  List<Map<String, dynamic>> _strips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('featured_strips')
        .select()
        .order('sort_order');
    if (mounted) {
      setState(() {
        _strips = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  Future<void> _delete(Object id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.card,
        title:
            const Text('Delete Strip', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure? This cannot be undone.',
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
    if (confirmed == true) {
      await Supabase.instance.client
          .from('featured_strips')
          .delete()
          .eq('id', id);
      if (mounted) await _load();
    }
  }

  Future<void> _toggle(String id, bool val) async {
    await Supabase.instance.client
        .from('featured_strips')
        .update({'is_active': val}).eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminPageHeader(
            title: 'Discover Strips',
            subtitle:
                'Horizontal image cards on the home screen — ${_strips.length} total',
            action: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.black),
              label: const Text('ADD STRIP'),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _loading
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(64),
                        child: CircularProgressIndicator(
                            color: AdminColors.accent)))
                : _buildList(context, screenW),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildList(BuildContext context, double screenW) {
    final isMobile = screenW < 600;
    if (_strips.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(64),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.view_carousel_outlined,
                    size: 52, color: AdminColors.textMuted),
                SizedBox(height: 16),
                Text('No discover strips yet.',
                    style: TextStyle(
                        fontFamily: 'Epilogue',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                SizedBox(height: 8),
                Text(
                    'Tap "ADD STRIP" to create a horizontal image card for the home screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Manrope', color: AdminColors.textMuted)),
              ])));
    }

    return Column(
        children: _strips.asMap().entries.map((e) {
      final s = e.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border)),
        child: Row(children: [
          // Image preview
          if (!isMobile) ...[
            Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                  color: AdminColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(8)),
              child: s['image_url'] != null &&
                      (s['image_url'] as String).isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(s['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image,
                                  color: AdminColors.textMuted))))
                  : const Center(
                      child: Icon(Icons.image_outlined,
                          color: AdminColors.textMuted, size: 32)),
            ),
            const SizedBox(width: 20),
          ],

          // Info
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(s['title'] as String? ?? '(No title)',
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Sort: ${s['sort_order'] ?? 0}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          color: AdminColors.textMuted)),
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AdminColors.accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(s['cta_label'] as String? ?? 'DISCOVER NOW',
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            color: AdminColors.accent,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
                if (s['action_url'] != null &&
                    (s['action_url'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(s['action_url'] as String,
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: AdminColors.textMuted),
                        overflow: TextOverflow.ellipsis),
                  ),
              ])),

          // Controls
          Switch(
              value: s['is_active'] as bool? ?? false,
              onChanged: (v) => _toggle(s['id'], v),
              activeThumbColor: AdminColors.success),
          InkWell(
              onTap: () => _showDialog(context, strip: s),
              child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit_outlined,
                      color: AdminColors.textMuted, size: 18))),
          InkWell(
              onTap: () => _delete(s['id']),
              child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete_outline,
                      color: AdminColors.error, size: 18))),
        ]),
      );
    }).toList());
  }

  void _showDialog(BuildContext context, {Map<String, dynamic>? strip}) {
    showDialog(
      context: context,
      builder: (_) => _StripDialog(strip: strip, onSaved: _load),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _StripDialog extends StatefulWidget {
  final Map<String, dynamic>? strip;
  final VoidCallback onSaved;
  const _StripDialog({this.strip, required this.onSaved});
  @override
  State<_StripDialog> createState() => _StripDialogState();
}

class _StripDialogState extends State<_StripDialog> {
  late final TextEditingController _title, _imageUrl, _cta, _sort;
  bool _active = true, _saving = false, _uploading = false;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final s = widget.strip;
    _title = TextEditingController(text: s?['title'] ?? '');
    _imageUrl = TextEditingController(text: s?['image_url'] ?? '');
    _cta = TextEditingController(text: s?['cta_label'] ?? 'DISCOVER NOW');
    _sort = TextEditingController(text: s?['sort_order']?.toString() ?? '0');
    _active = s?['is_active'] ?? true;
    _selectedCategoryId = _parseCategoryIdFromUrl(s?['action_url'] as String?);
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _imageUrl.dispose();
    _cta.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      final ext = file.extension ?? 'jpg';
      final path = 'strips/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage.from('strips').uploadBinary(
            path,
            file.bytes!,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
          );
      final url =
          Supabase.instance.client.storage.from('strips').getPublicUrl(path);
      if (mounted) setState(() => _imageUrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _loadCategories() async {
    final data = await Supabase.instance.client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('name');
    if (!mounted) return;
    setState(() => _categories = List<Map<String, dynamic>>.from(data));
    await _refreshCategoryImageIfNeeded();
  }

  Future<String?> _fetchCategoryImage(String categoryId) async {
    final response = await Supabase.instance.client
        .from('products')
        .select('images')
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1);
    if (response.isNotEmpty) {
      final record = response.first;
      final images = (record['images'] as List?)?.cast<String>() ?? [];
      return images.isNotEmpty ? images.first : null;
    }
    return null;
  }

  Future<void> _refreshCategoryImageIfNeeded() async {
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) return;
    if (_imageUrl.text.trim().isNotEmpty) return;

    final imageUrl = await _fetchCategoryImage(_selectedCategoryId!);
    if (!mounted || imageUrl == null || imageUrl.isEmpty) return;
    setState(() => _imageUrl.text = imageUrl);
  }

  String? _parseCategoryIdFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['categoryId'];
    } catch (_) {
      return null;
    }
  }

  String? _computeActionUrl() {
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      return '/search?categoryId=$_selectedCategoryId';
    }
    return widget.strip != null ? widget.strip!['action_url'] as String? : null;
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && _imageUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title or image URL.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'title': _title.text.trim(),
        'image_url': _imageUrl.text.trim(),
        'action_url': _computeActionUrl(),
        'cta_label':
            _cta.text.trim().isEmpty ? 'DISCOVER NOW' : _cta.text.trim(),
        'sort_order': int.tryParse(_sort.text) ?? 0,
        'is_active': _active,
      };
      if (widget.strip != null) {
        await Supabase.instance.client
            .from('featured_strips')
            .update(payload)
            .eq('id', widget.strip!['id']);
      } else {
        await Supabase.instance.client.from('featured_strips').insert(payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dialogW = w < 560 ? w * 0.95 : 520.0;

    return Dialog(
        child: Container(
      width: dialogW,
      padding: EdgeInsets.all(w < 560 ? 20 : 32),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  widget.strip == null
                      ? 'Add Discover Strip'
                      : 'Edit Discover Strip',
                  style: const TextStyle(
                      fontFamily: 'Epilogue',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 24),

              _tf(_title, 'Card Title (optional)'),
              const SizedBox(height: 20),

              // ── Image ────────────────────────────────────────────────────────
              const Text('Card Image',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 10),

              // Preview
              if (_imageUrl.text.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageUrl.text,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AdminColors.textMuted, size: 36))),
                  ),
                ),

              Row(children: [
                InkWell(
                  onTap: _uploading ? null : _pickAndUpload,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: AdminColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AdminColors.accent.withValues(alpha: 0.5))),
                    child: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AdminColors.accent))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.upload_file_outlined,
                                color: AdminColors.accent, size: 16),
                            SizedBox(width: 6),
                            Text('Upload',
                                style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    color: AdminColors.accent,
                                    fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('or',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        color: AdminColors.textMuted,
                        fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _imageUrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Paste image URL...',
                      hintStyle: const TextStyle(
                          color: AdminColors.textMuted, fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AdminColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AdminColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AdminColors.accent)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              _tf(_cta, 'CTA Button Label (e.g. DISCOVER NOW)'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                dropdownColor: AdminColors.surfaceHigh,
                decoration: const InputDecoration(
                  labelText: 'Target category',
                  helperText: 'Tap opens the selected category results',
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category['id'] as String,
                          child: Text(category['name'] as String),
                        ))
                    .toList(),
                onChanged: (value) async {
                  setState(() => _selectedCategoryId = value);
                  if (value != null) await _refreshCategoryImageIfNeeded();
                },
              ),
              const SizedBox(height: 16),
              _tf(_sort, 'Sort Order (0 = first)', type: TextInputType.number),
              const SizedBox(height: 16),

              CheckboxListTile(
                  title: const Text('Active',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: 13)),
                  subtitle: const Text(
                      'Only active strips appear on the home screen',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AdminColors.textMuted,
                          fontSize: 11)),
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
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text(widget.strip == null
                            ? 'ADD STRIP'
                            : 'SAVE CHANGES')),
              ]),
            ]),
      ),
    ));
  }

  Widget _tf(TextEditingController c, String label, {TextInputType? type}) =>
      TextField(
          controller: c,
          keyboardType: type,
          style: const TextStyle(
              fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
          decoration: InputDecoration(labelText: label));
}
