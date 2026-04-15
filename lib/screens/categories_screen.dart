// ─────────────────────────────────────────────────────────────────────────────
// categories_screen.dart — Category management with icon picker
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/theme.dart';
import '../layouts/admin_layout.dart';

// ── Available icons for categories ──────────────────────────────────────────
const _availableIcons = <Map<String, dynamic>>[
  {'name': 'layers_outlined', 'icon': Icons.layers_outlined, 'label': 'Layers'},
  {
    'name': 'dry_cleaning_outlined',
    'icon': Icons.dry_cleaning_outlined,
    'label': 'Clothing'
  },
  {
    'name': 'checkroom_outlined',
    'icon': Icons.checkroom_outlined,
    'label': 'Wardrobe'
  },
  {
    'name': 'local_offer_outlined',
    'icon': Icons.local_offer_outlined,
    'label': 'Offer'
  },
  {'name': 'watch_outlined', 'icon': Icons.watch_outlined, 'label': 'Watch'},
  {
    'name': 'shopping_bag_outlined',
    'icon': Icons.shopping_bag_outlined,
    'label': 'Bag'
  },
  {'name': 'face_outlined', 'icon': Icons.face_outlined, 'label': 'Face'},
  {'name': 'sports_outlined', 'icon': Icons.sports_outlined, 'label': 'Sports'},
  {'name': 'star_outline', 'icon': Icons.star_outline, 'label': 'Star'},
  {
    'name': 'diamond_outlined',
    'icon': Icons.diamond_outlined,
    'label': 'Diamond'
  },
  {
    'name': 'fitness_center_outlined',
    'icon': Icons.fitness_center_outlined,
    'label': 'Fitness'
  },
  {
    'name': 'luggage_outlined',
    'icon': Icons.luggage_outlined,
    'label': 'Luggage'
  },
  {
    'name': 'category_outlined',
    'icon': Icons.category_outlined,
    'label': 'Category'
  },
  {
    'name': 'color_lens_outlined',
    'icon': Icons.color_lens_outlined,
    'label': 'Colors'
  },
  {
    'name': 'beach_access_outlined',
    'icon': Icons.beach_access_outlined,
    'label': 'Beach'
  },
  {
    'name': 'child_care_outlined',
    'icon': Icons.child_care_outlined,
    'label': 'Kids'
  },
  {
    'name': 'weekend_outlined',
    'icon': Icons.weekend_outlined,
    'label': 'Casual'
  },
  {'name': 'wc_outlined', 'icon': Icons.wc, 'label': 'Gender'},
  {
    'name': 'directions_walk_outlined',
    'icon': Icons.directions_walk_outlined,
    'label': 'Walk'
  },
  {
    'name': 'emoji_nature_outlined',
    'icon': Icons.emoji_nature_outlined,
    'label': 'Nature'
  },
];

IconData _iconFromName(String? name) {
  final found = _availableIcons.firstWhere(
    (i) => i['name'] == name,
    orElse: () => _availableIcons.last,
  );
  return found['icon'] as IconData;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _cats = [];
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
        .from('categories')
        .select()
        .order('sort_order');
    if (mounted) {
      setState(() {
        _cats = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Delete Category',
            style: TextStyle(
                fontFamily: 'Epilogue',
                color: Colors.white,
                fontWeight: FontWeight.w800)),
        content: const Text(
            'Products in this category will NOT be deleted, but will be uncategorised.',
            style: TextStyle(
                fontFamily: 'Manrope', color: AdminColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('CANCEL')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
              child:
                  const Text('DELETE', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final productRefs = await Supabase.instance.client
          .from('products')
          .select('id')
          .eq('category_id', id)
          .limit(1);

      if (productRefs.isNotEmpty) {
        await Supabase.instance.client
            .from('categories')
            .update({'is_active': false}).eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: AdminColors.warning,
              content: Text(
                  'Category deactivated instead of deleted because products use it.',
                  style:
                      TextStyle(fontFamily: 'Manrope', color: Colors.black))));
        }
      } else {
        await Supabase.instance.client.from('categories').delete().eq('id', id);
      }
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
            title: 'Categories',
            subtitle: '${_cats.length} categories',
            action: ElevatedButton.icon(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.black),
              label: const Text('ADD CATEGORY'),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AdminColors.accent))
                : _buildGrid(context),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_cats.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(48),
              child: Text('No categories yet.',
                  style: TextStyle(
                      fontFamily: 'Manrope', color: AdminColors.textMuted))));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? 500 : 300,
        crossAxisSpacing: isMobile ? 8 : 16,
        mainAxisSpacing: isMobile ? 8 : 16,
        childAspectRatio: isMobile ? 2.8 : 2.0,
      ),
      itemCount: _cats.length,
      itemBuilder: (_, i) {
        final c = _cats[i];
        final iconName = c['icon_name'] as String?;
        final isActive = c['is_active'] as bool? ?? true;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive
                    ? AdminColors.border
                    : AdminColors.error.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AdminColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(_iconFromName(iconName),
                    color: AdminColors.accent, size: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c['name'] as String,
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                  Text(
                      '${isActive ? "Active" : "Inactive"} · order: ${c['sort_order']}',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          color: isActive
                              ? AdminColors.textMuted
                              : AdminColors.error)),
                ])),
            Column(children: [
              InkWell(
                  onTap: () => _showDialog(context, cat: c),
                  child: const Icon(Icons.edit_outlined,
                      color: AdminColors.textMuted, size: 16)),
              const SizedBox(height: 8),
              InkWell(
                  onTap: () => _delete(c['id']),
                  child: const Icon(Icons.delete_outline,
                      color: AdminColors.error, size: 16)),
            ]),
          ]),
        );
      },
    );
  }

  void _showDialog(BuildContext context, {Map<String, dynamic>? cat}) {
    showDialog(
        context: context, builder: (_) => _CatDialog(cat: cat, onSaved: _load));
  }
}

// ── Category Dialog (with icon picker) ──────────────────────────────────────

class _CatDialog extends StatefulWidget {
  final Map<String, dynamic>? cat;
  final VoidCallback onSaved;
  const _CatDialog({this.cat, required this.onSaved});
  @override
  State<_CatDialog> createState() => _CatDialogState();
}

class _CatDialogState extends State<_CatDialog> {
  late final TextEditingController _name, _slug, _desc, _sort;
  bool _active = true;
  bool _loading = false;
  String _selectedIconName = 'category_outlined';

  @override
  void initState() {
    super.initState();
    final c = widget.cat;
    _name = TextEditingController(text: c?['name'] ?? '');
    _slug = TextEditingController(text: c?['slug'] ?? '');
    _desc = TextEditingController(text: c?['description'] ?? '');
    _sort = TextEditingController(text: c?['sort_order']?.toString() ?? '0');
    _active = c?['is_active'] ?? true;
    _selectedIconName = c?['icon_name'] ?? 'category_outlined';
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _desc.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final slug = _slug.text.trim().isNotEmpty
          ? _slug.text.trim()
          : _name.text.toLowerCase().replaceAll(' ', '-');

      final data = {
        'name': _name.text.trim(),
        'slug': slug,
        'description': _desc.text.trim(),
        'sort_order': int.tryParse(_sort.text) ?? 0,
        'is_active': _active,
        'icon_name': _selectedIconName,
      };

      if (widget.cat != null) {
        await Supabase.instance.client
            .from('categories')
            .update(data)
            .eq('id', widget.cat!['id']);
      } else {
        await Supabase.instance.client.from('categories').insert(data);
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
    final dialogWidth = w < 560 ? w * 0.92 : 500.0;
    final isMobile = w < 560;
    final iconCols = isMobile ? 4 : 5;

    return Dialog(
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.cat == null ? 'Add Category' : 'Edit Category',
                    style: const TextStyle(
                        fontFamily: 'Epilogue',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 24),
                _tf(_name, 'Category Name *'),
                const SizedBox(height: 16),
                _tf(_slug, 'Slug (auto-generated if empty)'),
                const SizedBox(height: 16),
                _tf(_desc, 'Description'),
                const SizedBox(height: 16),
                _tf(_sort, 'Sort Order', type: TextInputType.number),
                const SizedBox(height: 20),

                // ── Icon Picker ────────────────────────────────────────────────
                const Text('ICON',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textMuted)),
                const SizedBox(height: 12),
                // Currently selected icon preview
                Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: AdminColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.accent)),
                    child: Icon(_iconFromName(_selectedIconName),
                        color: AdminColors.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('Selected: $_selectedIconName',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: AdminColors.textMuted)),
                ]),
                const SizedBox(height: 12),
                // Grid of icons to pick from
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: GridView.count(
                    crossAxisCount: iconCols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: _availableIcons.map((item) {
                      final name = item['name'] as String;
                      final icon = item['icon'] as IconData;
                      final label = item['label'] as String;
                      final selected = _selectedIconName == name;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIconName = name),
                        child: Tooltip(
                          message: label,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AdminColors.accent.withOpacity(0.2)
                                  : AdminColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selected
                                    ? AdminColors.accent
                                    : AdminColors.border,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Icon(icon,
                                color: selected
                                    ? AdminColors.accent
                                    : AdminColors.textMuted,
                                size: 20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
                  controlAffinity: ListTileControlAffinity.leading,
                ),
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
                          : Text(widget.cat == null ? 'ADD' : 'SAVE')),
                ]),
              ]),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, {TextInputType? type}) =>
      TextField(
          controller: c,
          keyboardType: type,
          style: const TextStyle(
              fontFamily: 'Manrope', color: Colors.white, fontSize: 13),
          decoration: InputDecoration(labelText: label));
}
