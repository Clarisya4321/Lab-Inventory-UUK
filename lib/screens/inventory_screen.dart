import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/inventory_service.dart';
import '../widgets/inventory_card.dart';
import '../widgets/search_field.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _service = InventoryService();

  late final Stream<List<Map<String, dynamic>>> _stream = _service
      .itemsStream();

  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String pesan, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: error ? AppColors.borrowed : AppColors.available,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Map<String, dynamic>?> _formBarang({Map<String, dynamic>? item}) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return FormBarangDialog(item: item);
      },
    );
  }

  Future<void> _tambahBarang() async {
    final data = await _formBarang();

    if (data == null) return;

    try {
      await _service.addItem({...data, 'status': 'Available'});

      _snack('Barang berhasil ditambahkan');
    } catch (e) {
      _snack('Gagal menambahkan barang: $e', error: true);
    }
  }

  Future<void> _editBarang(Map<String, dynamic> item) async {
    final data = await _formBarang(item: item);

    if (data == null) return;

    try {
      await _service.updateItem(item['item_id'].toString(), data);

      _snack('Barang berhasil diperbarui');
    } catch (e) {
      _snack('Gagal mengedit barang: $e', error: true);
    }
  }

  Future<void> _hapusBarang(Map<String, dynamic> item) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text(
          'Apakah kamu yakin ingin menghapus '
          '"${item['item_name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 219, 25, 11),
              foregroundColor: const Color.fromARGB(255, 201, 14, 14),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ya != true) return;

    try {
      await _service.deleteItem(item['item_id'].toString());

      _snack('Barang berhasil dihapus');
    } catch (e) {
      _snack('Gagal menghapus barang: $e', error: true);
    }
  }

  Future<void> _kembalikan(Map<String, dynamic> item) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kembalikan Barang'),
        content: Text('Kembalikan "${item['item_name']}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );

    if (ya != true) return;

    try {
      await _service.returnItem(item['item_id'].toString());

      _snack('${item['item_name']} berhasil dikembalikan');
    } catch (e) {
      _snack('Gagal mengembalikan barang: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Membaca role yang dikirim dari LoginScreen.
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'user';

    final isOwner = role == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kotak Inventaris',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appGradient),
        ),
      ),

      // Tombol tambah hanya muncul untuk Owner.
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: _tambahBarang,
              backgroundColor: const Color.fromARGB(255, 246, 106, 13),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Barang'),
            )
          : null,

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat data inventaris.\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final semuaBarang = snapshot.data!;

                final q = _query.trim().toLowerCase();

                final items = semuaBarang.where((item) {
                  final teks =
                      '${item['item_name']} '
                              '${item['category']} '
                              '${item['code']}'
                          .toLowerCase();

                  return teks.contains(q);
                }).toList();

                if (semuaBarang.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada data inventaris.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }

                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada barang yang cocok.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    final tersedia = item['status'] == 'Available';

                    final dipinjam = item['status'] == 'Borrowed';

                    return InventoryCard(
                      item: item,

                      onTap: () {
                        showItemDetail(context, item);
                      },

                      // Edit hanya untuk Owner.
                      onEdit: isOwner && tersedia
                          ? () => _editBarang(item)
                          : null,

                      // Hapus hanya untuk Owner.
                      onDelete: isOwner && tersedia
                          ? () => _hapusBarang(item)
                          : null,

                      // Pengelolaan pengembalian hanya untuk Owner.
                      onReturn: isOwner && dipinjam
                          ? () => _kembalikan(item)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// FORM TAMBAH DAN EDIT BARANG
// ==================================================

class FormBarangDialog extends StatefulWidget {
  final Map<String, dynamic>? item;

  const FormBarangDialog({super.key, this.item});

  @override
  State<FormBarangDialog> createState() => _FormBarangDialogState();
}

class _FormBarangDialogState extends State<FormBarangDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _kodeController;
  late final TextEditingController _gambarController;
  late final TextEditingController _spesifikasiController;

  late final List<String> _kategoriList;

  late String _kategori;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _namaController = TextEditingController(
      text: item?['item_name']?.toString() ?? '',
    );

    _kodeController = TextEditingController(
      text: item?['code']?.toString() ?? '',
    );

    _gambarController = TextEditingController(
      text: item?['image']?.toString() ?? '',
    );

    _spesifikasiController = TextEditingController(
      text: item?['spesification']?.toString() ?? '',
    );

    _kategoriList = kCategories.map((e) => e.toString()).toList();

    if (_kategoriList.isEmpty) {
      _kategoriList.add('Umum');
    }

    _kategori = item?['category']?.toString() ?? _kategoriList.first;

    if (!_kategoriList.contains(_kategori)) {
      _kategoriList.add(_kategori);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _gambarController.dispose();
    _spesifikasiController.dispose();

    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop({
      'item_name': _namaController.text.trim(),
      'category': _kategori,
      'code': _kodeController.text.trim(),
      'image': _gambarController.text.trim(),
      'spesification': _spesifikasiController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      title: Text(
        widget.item == null ? 'Tambah Barang' : 'Edit Barang',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),

      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama barang wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _kategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _kategoriList.map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _kategori = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _kodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Barang / Serial',
                    prefixIcon: Icon(Icons.qr_code),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kode barang wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _gambarController,
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar',
                    prefixIcon: Icon(Icons.image_outlined),
                    border: OutlineInputBorder(),
                    hintText: 'https://...',
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _spesifikasiController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Spesifikasi Barang',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Spesifikasi wajib diisi';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Batal'),
        ),

        ElevatedButton(
          onPressed: _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 226, 11, 11),
            foregroundColor: const Color.fromARGB(255, 198, 27, 27),
          ),
          child: Text(widget.item == null ? 'Simpan' : 'Perbarui'),
        ),
      ],
    );
  }
}
