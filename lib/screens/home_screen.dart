import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/inventory_service.dart';
import '../widgets/carousel_banner.dart';
import '../widgets/inventory_card.dart';
import '../widgets/search_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InventoryService _service = InventoryService();

  late final Stream<List<Map<String, dynamic>>> _stream = _service
      .itemsStream();

  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _category = 'Semua';

  @override
  void initState() {
    super.initState();
    _isiDataAwal();
  }

  Future<void> _isiDataAwal() async {
    try {
      final berhasil = await _service.seedDummyData();

      if (!mounted) return;

      if (berhasil) {
        _snack('Data inventaris berhasil ditambahkan.');
      }
    } catch (e) {
      debugPrint('Gagal mengisi data awal: $e');
    }
  }

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

  Future<bool> _tanya(String judul, String pesan) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(judul),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pinjam'),
          ),
        ],
      ),
    );

    return hasil ?? false;
  }

  Future<void> _pinjam(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack('Silakan login terlebih dahulu', error: true);
      return;
    }

    final ya = await _tanya(
      'Pinjam Barang',
      'Apakah kamu yakin ingin meminjam "${item['item_name']}"?',
    );

    if (!ya) return;

    try {
      await _service.borrowItem(uid: user.uid, item: item);

      if (!mounted) return;

      _snack('Berhasil meminjam ${item['item_name']}');
    } catch (e) {
      if (!mounted) return;

      _snack('Gagal meminjam: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: SearchField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
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
                          'Gagal memuat data. Periksa Rules Firestore.\n\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Mengambil SEMUA barang tanpa memfilter status.
                  final semuaBarang = snapshot.data!;

                  final q = _query.trim().toLowerCase();

                  // Filter pencarian.
                  final hasilCari = semuaBarang.where((item) {
                    final teks =
                        '${item['item_name']} '
                                '${item['category']} '
                                '${item['code']}'
                            .toLowerCase();

                    return teks.contains(q);
                  }).toList();

                  // Mengambil semua kategori dari data Firestore.
                  final kategori = <String>[
                    'Semua',
                    ...{
                      ...kCategories,
                      ...semuaBarang
                          .map((e) => (e['category'] ?? '').toString())
                          .where((c) => c.isNotEmpty),
                    },
                  ];

                  // Filter berdasarkan kategori.
                  final perKategori = _category == 'Semua'
                      ? hasilCari
                      : hasilCari
                            .where((e) => e['category'] == _category)
                            .toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const CarouselBanner(),
                      const SizedBox(height: 22),

                      if (semuaBarang.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Belum ada barang inventaris.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      else ...[
                        _bagian(
                          judul: 'Semua Barang',
                          ikon: Icons.inventory_2_rounded,
                          warna: AppColors.primary,
                          items: hasilCari,
                        ),

                        _bagian(
                          judul: 'Kategori Peralatan',
                          ikon: Icons.category_rounded,
                          warna: AppColors.purple,
                          items: perKategori,
                          filter: _chips(
                            kategori,
                            _category,
                            (v) => setState(() => _category = v),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(
    List<String> opsi,
    String terpilih,
    ValueChanged<String> onPilih,
  ) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opsi.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final o = opsi[i];
          final aktif = o == terpilih;

          return ChoiceChip(
            label: Text(o),
            selected: aktif,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: aktif ? AppColors.primary : const Color(0xFFDDE3F3),
            ),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: aktif ? Colors.white : AppColors.text,
            ),
            onSelected: (_) => onPilih(o),
          );
        },
      ),
    );
  }

  Widget _bagian({
    required String judul,
    required IconData ikon,
    required Color warna,
    required List<Map<String, dynamic>> items,
    Widget? filter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ikon, size: 18, color: warna),
            ),
            const SizedBox(width: 10),
            Text(
              judul,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${items.length} barang',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: warna,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (filter != null) ...[filter, const SizedBox(height: 10)],

        SizedBox(
          height: 215,
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada data yang cocok',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 160,
                    child: InventoryCard(
                      item: items[i],
                      compact: true,
                      onTap: () => showItemDetail(context, items[i]),
                      onBorrow: () => _pinjam(items[i]),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 22),
      ],
    );
  }
}
