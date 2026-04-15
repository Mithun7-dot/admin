// ─────────────────────────────────────────────────────────────────────────────
// banners_screen.dart — Home screen banner management
// Route: /banners
//
// Banners are the hero/promotional images shown in the carousel on the
// consumer app's home screen.
//
// Features:
//   • Lists banners in a vertical card list with image preview
//   • Toggle active/inactive per banner (Switch widget)
//   • Add / Edit via dialog (_BannerDialog)
//   • Delete banner
//   • Sort order controls which banner appears first in the carousel
//   • CTA label customisation (matches consumer app's cta_label field)
//   • Local file upload OR URL paste for banner image
//
// Supabase table: banners
// ─────────────────────────────────────────────────────────────────────────────

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});
  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Fetches all banners ordered by sort_order (lowest = first in carousel).
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('banners')
        .select()
        .order('sort_order');
    if (mounted) {
      setState(() {
        _banners = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  /// Deletes a banner by ID.
  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('banners').delete().eq('id', id);
    if (mounted) _load();
  }

  /// Toggles the active state of a banner.
  /// Inactive banners are hidden from the consumer app's home screen.
  Future<void> _toggle(String id, bool val) async {
    await Supabase.instance.client
        .from('banners')
        .update({'is_active': val}).eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final pad = responsivePadding(context);

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AdminPageHeader(
            title: 'Banners',
            subtitle: 'Home screen hero banners — ${_banners.length} total',
            action: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.black),
              label: const Text('ADD BANNER'),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AdminColors.accent))
                : _buildList(context),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_banners.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.image_outlined,
                    size: 48, color: AdminColors.textMuted),
                SizedBox(height: 16),
                Text(
                    'No banners yet. Tap "ADD BANNER" to create your first hero banner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Manrope', color: AdminColors.textMuted)),
              ])));
    }

    // Vertical list of banner cards
    return Column(
        children: _banners.asMap().entries.map((e) {
      final b = e.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border)),
        child: Row(children: [
          // ── Image preview (120×70 — hidden on mobile) ────────────────────
          if (!isMobile) ...[
            Container(
                width: 120,
                height: 70,
                decoration: BoxDecoration(
                    color: AdminColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(6)),
                child: b['image_url'] != null &&
                        (b['image_url'] as String).isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(b['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image,
                                    color: AdminColors.textMuted))))
                    : const Center(
                        child: Icon(Icons.image_outlined,
                            color: AdminColors.textMuted, size: 28))),
            const SizedBox(width: 20),
          ],

          // ── Banner info ─────────────────────────────────────────────────────
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(b['title'] as String? ?? '(No title)',
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (b['subtitle'] != null &&
                    (b['subtitle'] as String).isNotEmpty)
                  Text(b['subtitle'] as String,
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AdminColors.textMuted)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Sort: ${b['sort_order']}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          color: AdminColors.textMuted)),
                  const SizedBox(width: 16),
                  if (b['cta_label'] != null &&
                      (b['cta_label'] as String).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AdminColors.accent.withOpacity(0.4)),
                      ),
                      child: Text('CTA: ${b['cta_label']}',
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9,
                              color: AdminColors.accent,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
              ])),

          // ── Active toggle ───────────────────────────────────────────────────
          Switch(
              value: b['is_active'] as bool? ?? false,
              onChanged: (v) => _toggle(b['id'], v),
              activeThumbColor: AdminColors.success),
          const SizedBox(width: 8),

          // Edit button
          InkWell(
              onTap: () => _showDialog(context, banner: b),
              child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit_outlined,
                      color: AdminColors.textMuted, size: 18))),

          // Delete button
          InkWell(
              onTap: () => _delete(b['id']),
              child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete_outline,
                      color: AdminColors.error, size: 18))),
        ]),
      );
    }).toList());
  }

  void _showDialog(BuildContext context, {Map<String, dynamic>? banner}) {
    showDialog(
        context: context,
        builder: (_) => _BannerDialog(banner: banner, onSaved: _load));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner Add/Edit Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _BannerDialog extends StatefulWidget {
  final Map<String, dynamic>? banner; // null = add, non-null = edit
  final VoidCallback onSaved;
  const _BannerDialog({this.banner, required this.onSaved});
  @override
  State<_BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<_BannerDialog> {
  late final TextEditingController _title,
      _subtitle,
      _imageUrl,
      _actionUrl,
      _sort,
      _ctaLabel;
  bool _active = true, _loading = false, _uploadingImage = false;
  List<Map<String, dynamic>> _categories = [];
  bool _linkToCategory = true;
  Map<String, dynamic>? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _title = TextEditingController(text: b?['title'] ?? '');
    _subtitle = TextEditingController(text: b?['subtitle'] ?? '');
    _imageUrl = TextEditingController(text: b?['image_url'] ?? '');
    _actionUrl = TextEditingController(text: b?['action_url'] ?? '');
    _sort = TextEditingController(text: b?['sort_order']?.toString() ?? '0');
    _ctaLabel = TextEditingController(text: b?['cta_label'] ?? 'SHOP NOW');
    _active = b?['is_active'] ?? true;
    _loadCategories();
    // Check if action_url is a category link
    final actionUrl = b?['action_url'] as String? ?? '';
    if (actionUrl.startsWith('/search?categoryId=')) {
      _linkToCategory = true;
      // Will set _selectedCategory after categories load
    } else {
      _linkToCategory = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .order('name');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
          // Set selected category if editing and linking to category
          if (_linkToCategory && widget.banner != null) {
            final actionUrl = widget.banner!['action_url'] as String;
            final categoryId =
                actionUrl.replaceFirst('/search?categoryId=', '');
            _selectedCategory = _categories.firstWhere(
              (cat) => cat['id'].toString() == categoryId,
              orElse: () => {},
            );
            if (_selectedCategory!.isEmpty) _selectedCategory = null;
          }
        });
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _imageUrl.dispose();
    _actionUrl.dispose();
    _sort.dispose();
    _ctaLabel.dispose();
    super.dispose();
  }

  // ── Upload banner image from local file ────────────────────────────────────
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
      final path = 'banners/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage.from('banners').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
          );
      final publicUrl =
          Supabase.instance.client.storage.from('banners').getPublicUrl(path);
      if (mounted) setState(() => _imageUrl.text = publicUrl);
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

  /// Saves the banner to Supabase (insert or update).
  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a banner title.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final data = {
        'title': _title.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'image_url': _imageUrl.text.trim(),
        'action_url': _actionUrl.text.trim(),
        'sort_order': int.tryParse(_sort.text) ?? 0,
        'is_active': _active,
        'cta_label':
            _ctaLabel.text.trim().isEmpty ? 'SHOP NOW' : _ctaLabel.text.trim(),
      };
      if (widget.banner != null) {
        await Supabase.instance.client
            .from('banners')
            .update(data)
            .eq('id', widget.banner!['id']);
      } else {
        await Supabase.instance.client.from('banners').insert(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dialogWidth = w < 560 ? w * 0.95 : 520.0;
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
              Text(widget.banner == null ? 'Add Banner' : 'Edit Banner',
                  style: const TextStyle(
                      fontFamily: 'Epilogue',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 24),

              // Title & Subtitle
              _tf(_title, 'Banner Title *'),
              const SizedBox(height: 16),
              _tf(_subtitle, 'Subtitle (optional)'),
              const SizedBox(height: 20),

              // ── Banner Image ────────────────────────────────────────────────
              const Text('Banner Image',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 10),

              // Image preview
              if (_imageUrl.text.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AdminColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageUrl.text,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AdminColors.textMuted, size: 36))),
                  ),
                ),

              // Upload / replace banner image with optional URL override
              Row(children: [
                InkWell(
                  onTap: _uploadingImage ? null : _pickAndUploadImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AdminColors.accent.withOpacity(0.5)),
                    ),
                    child: _uploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AdminColors.accent))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.upload_file_outlined,
                                color: AdminColors.accent, size: 16),
                            const SizedBox(width: 6),
                            Text(widget.banner == null ? 'Upload' : 'Replace',
                                style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    color: AdminColors.accent,
                                    fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ),
                const SizedBox(width: 10),
                if (_imageUrl.text.isNotEmpty) ...[
                  OutlinedButton(
                    onPressed: _uploadingImage
                        ? null
                        : () => setState(() => _imageUrl.clear()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AdminColors.error),
                    ),
                    child: const Text('Remove',
                        style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: AdminColors.error)),
                  ),
                  const SizedBox(width: 10),
                ],
                const Text('or',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        color: AdminColors.textMuted,
                        fontSize: 12)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _imageUrl,
                    onChanged: (_) => setState(() {}), // refresh preview
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
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Action Link ────────────────────────────────────────────────
              const Text('Action Link',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 10),

              // Radio buttons for link type
              RadioListTile<bool>(
                title: const Text('Link to Category',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontSize: 13)),
                value: true,
                groupValue: _linkToCategory,
                onChanged: (value) => setState(() => _linkToCategory = value!),
                activeColor: AdminColors.accent,
                contentPadding: EdgeInsets.zero,
              ),
              if (_linkToCategory) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      if (value != null) {
                        _actionUrl.text = '/search?categoryId=${value['id']}';
                      } else {
                        _actionUrl.text = '';
                      }
                    });
                  },
                  items: _categories.map((category) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: category,
                      child: Text(category['name'] as String,
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: Colors.white,
                              fontSize: 13)),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Select Category',
                    labelStyle: const TextStyle(
                        fontFamily: 'Manrope',
                        color: AdminColors.textMuted,
                        fontSize: 13),
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
                  ),
                  dropdownColor: AdminColors.surface,
                  style: const TextStyle(
                      fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
                ),
              ],
              RadioListTile<bool>(
                title: const Text('Custom URL',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontSize: 13)),
                value: false,
                groupValue: _linkToCategory,
                onChanged: (value) => setState(() => _linkToCategory = value!),
                activeColor: AdminColors.accent,
                contentPadding: EdgeInsets.zero,
              ),
              if (!_linkToCategory) ...[
                const SizedBox(height: 8),
                _tf(_actionUrl,
                    'Action URL (on tap) — e.g. /search?categoryId=xxx'),
              ],
              const SizedBox(height: 16),
              _tf(_ctaLabel, 'CTA Button Label (e.g. SHOP NOW)'),
              const SizedBox(height: 16),
              _tf(_sort, 'Sort Order (0 = first)', type: TextInputType.number),
              const SizedBox(height: 16),

              // Active toggle
              CheckboxListTile(
                  title: const Text('Active',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: 13)),
                  subtitle: const Text(
                      'Inactive banners are hidden from the home screen',
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
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text(widget.banner == null
                            ? 'ADD BANNER'
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
