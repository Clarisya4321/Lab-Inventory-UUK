import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/inventory_service.dart';
import '../widgets/carousel_banner.dart';
import '../widgets/inventory_card.dart';
import '../widgets/search_field.dart';

/// Beranda: Search Bar, Carousel Slider, dan 3 bagian scroll horizontal
/// (Semua Data, Kategori Peralatan, Status).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InventoryService _service = InventoryService();
  late final Stream<List<Map<String, dynamic>>> _stream =
      _service.itemsStream();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _category = 'Semua';
  String _status = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _cari(List<Map<String, dynamic>> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((i) {
      final teks = '${i['item_name']} ${i['category']} ${i['code']}'
          .toLowerCase();
      return teks.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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

            final all = snapshot.data!;
            final hasilCari = _cari(all);

            final kategori = <String>[
              'Semua',
              ...{
                ...kCategories,
                ...all
                    .map((e) => (e['category'] ?? '').toString())
                    .where((c) => c.isNotEmpty),
              },
            ];
            final perKategori = _category == 'Semua'
                ? hasilCari
                : hasilCari.where((e) => e['category'] == _category).toList();
            final perStatus = _status == 'Semua'
                ? hasilCari
                : hasilCari.where((e) => e['status'] == _status).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // 1. Search Bar
                SearchField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 18),

                // 2. Carousel Slider
                const CarouselBanner(),
                const SizedBox(height: 22),

                if (all.isEmpty)
                  const SeedDataBox()
                else ...[
                  // 3a. Semua Data
                  _bagian(
                    judul: 'Semua Data',
                    ikon: Icons.apps_rounded,
                    warna: AppColors.primary,
                    items: hasilCari,
                  ),

                  // 3b. Kategori Peralatan
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

                  // 3c. Status
                  _bagian(
                    judul: 'Status',
                    ikon: Icons.fact_check_rounded,
                    warna: AppColors.accent,
                    items: perStatus,
                    filter: _chips(
                      const ['Semua', 'Available', 'Borrowed'],
                      _status,
                      (v) => setState(() => _status = v),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chips(
      List<String> opsi, String terpilih, ValueChanged<String> onPilih) {
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
                color: aktif ? AppColors.primary : const Color(0xFFDDE3F3)),
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
            Text(judul,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${items.length} barang',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: warna)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filter != null) ...[filter, const SizedBox(height: 10)],
        SizedBox(
          height: 215,
          child: items.isEmpty
              ? const Center(
                  child: Text('Tidak ada data yang cocok',
                      style: TextStyle(color: AppColors.muted)),
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
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}
