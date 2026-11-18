import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_theme.dart';
import '../services/inventory_service.dart';

class ItemImage extends StatelessWidget {
  final String url;
  final String category;

  const ItemImage({super.key, required this.url, required this.category});

  Widget _placeholder() {
    final c = categoryColor(category);

    return Container(
      color: c.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(categoryIcon(category), color: c, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stack) => _placeholder(),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final c = categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(category), size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onBorrow;
  final VoidCallback? onReturn;

  const InventoryCard({
    super.key,
    required this.item,
    this.compact = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onBorrow,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final name = (item['item_name'] ?? '-').toString();
    final category = (item['category'] ?? '-').toString();
    final status = (item['status'] ?? 'Available').toString();
    final image = (item['image'] ?? '').toString();
    final code = (item['code'] ?? '-').toString();

    return compact
        ? _compact(name, category, status, image)
        : _list(name, category, status, image, code);
  }

  Widget _compact(String name, String category, String status, String image) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ItemImage(url: image, category: category),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: categoryColor(category),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: status),
                  if (status == 'Available' && onBorrow != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: onBorrow,
                        icon: const Icon(Icons.shopping_bag_rounded, size: 15),
                        label: const Text(
                          'Pinjam',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    String name,
    String category,
    String status,
    String image,
    String code,
  ) {
    final hasMenu =
        status == 'Available' && (onEdit != null || onDelete != null);

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: ItemImage(url: image, category: category),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        if (hasMenu)
                          SizedBox(
                            width: 28,
                            height: 24,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: AppColors.muted,
                              ),
                              onSelected: (v) {
                                if (status != 'Available') return;
                                if (v == 'edit') onEdit?.call();
                                if (v == 'delete') onDelete?.call();
                              },
                              itemBuilder: (context) => [
                                if (onEdit != null)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                if (onDelete != null)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_rounded,
                                          size: 18,
                                          color: AppColors.borrowed,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Hapus'),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _CategoryChip(category: category),
                        StatusBadge(status: status),
                      ],
                    ),
                    if (onBorrow != null || onReturn != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: status == 'Borrowed'
                            ? OutlinedButton.icon(
                                onPressed: onReturn,
                                icon: const Icon(
                                  Icons.assignment_return_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Kembalikan',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color.fromARGB(
                                    255,
                                    215,
                                    27,
                                    14,
                                  ),
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 216, 27, 13),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: onBorrow,
                                icon: const Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Pinjam',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showItemDetail(BuildContext context, Map<String, dynamic> item) {
  final name = (item['item_name'] ?? '-').toString();
  final category = (item['category'] ?? '-').toString();
  final status = (item['status'] ?? 'Available').toString();

  Widget row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) {
      final tinggiLayar = MediaQuery.of(sheetContext).size.height;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          bool sedangMeminjam = false;

          return SizedBox(
            height: tinggiLayar * 0.90,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: tinggiLayar * 0.48,
                          child: ItemImage(
                            url: (item['image'] ?? '').toString(),
                            category: category,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 12),
                              StatusBadge(status: status),
                              const SizedBox(height: 22),
                              row(
                                'Kode Barang',
                                (item['code'] ?? '-').toString(),
                              ),
                              row('Kategori', category),
                              row(
                                'Spesifikasi',
                                (item['spesification'] ?? '-').toString(),
                              ),
                              row(
                                'Ditambahkan',
                                formatTanggal(item['created_at']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (status == 'Available')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: sedangMeminjam
                            ? null
                            : () async {
                                final user = FirebaseAuth.instance.currentUser;

                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Silakan login terlebih dahulu.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  sedangMeminjam = true;
                                });

                                try {
                                  await InventoryService().borrowItem(
                                    uid: user.uid,
                                    item: item,
                                  );

                                  if (!context.mounted) return;

                                  Navigator.pop(sheetContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pengajuan peminjaman berhasil!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;

                                  setSheetState(() {
                                    sedangMeminjam = false;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal mengajukan pinjaman: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: sedangMeminjam
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.shopping_bag_rounded),
                        label: Text(
                          sedangMeminjam ? 'Memproses...' : 'Ajukan Pinjam',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class SeedDataBox extends StatefulWidget {
  const SeedDataBox({super.key});

  @override
  State<SeedDataBox> createState() => _SeedDataBoxState();
}

class _SeedDataBoxState extends State<SeedDataBox> {
  bool _loading = false;

  Future<void> _seed() async {
    setState(() => _loading = true);

    try {
      await InventoryService().seedDummyData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengisi data dummy: $e'),
            backgroundColor: AppColors.borrowed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada data inventaris',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Isi data dummy ke Firestore atau tambah barang manual.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _seed,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Isi Data Dummy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
