import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _waktu(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items');

  // URL foto barang
  final Map<String, String> _images = {
    'LAB-KMP-001':
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600',
    'LAB-KMP-002':
        'https://images.unsplash.com/photo-1587831990711-23ca6441447b?w=600',
    'LAB-JRG-001':
        'https://images.unsplash.com/photo-1606904825846-647eb07f5be2?w=600',
    'LAB-JRG-002':
        'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=600',
    'LAB-JRG-003':
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600',
    'LAB-ELK-001':
        'https://images.unsplash.com/photo-1553406830-ef2513450d76?w=600',
    'LAB-ELK-002':
        'https://images.unsplash.com/photo-1587135991058-8816b028691f?w=600',
    'LAB-UKR-001':
        'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=600',
    'LAB-PRS-001':
        'https://images.unsplash.com/photo-1535016120720-40c646be5580?w=600',
  };

  // Menampilkan semua barang secara real-time
  Stream<List<Map<String, dynamic>>> itemsStream() {
    return _items.snapshots().map((snap) {
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['item_id'] = d.id;
        return data;
      }).toList();

      list.sort(
        (a, b) => _waktu(b['created_at']).compareTo(_waktu(a['created_at'])),
      );

      return list;
    });
  }

  // Menambahkan barang
  Future<void> addItem(Map<String, dynamic> data) async {
    final ref = _items.doc();

    await ref.set({
      'item_id': ref.id,
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Mengedit barang
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _items.doc(itemId).update(data);
  }

  // Menghapus barang
  Future<void> deleteItem(String itemId) async {
    await _items.doc(itemId).delete();
  }

  // Meminjam barang
  Future<void> borrowItem({
    required String uid,
    required Map<String, dynamic> item,
  }) async {
    final itemId = item['item_id'].toString();

    final borrowRef = _db
        .collection('users')
        .doc(uid)
        .collection('borrowings')
        .doc();

    final batch = _db.batch();

    batch.set(borrowRef, {
      'borrow_id': borrowRef.id,
      'item_id': itemId,
      'item_name': item['item_name'],
      'borrow_date': FieldValue.serverTimestamp(),
    });

    batch.update(_items.doc(itemId), {'status': 'Borrowed'});

    await batch.commit();
  }

  // Mengembalikan barang
  Future<void> returnItem(String itemId) async {
    await _items.doc(itemId).update({'status': 'Available'});
  }

  // Riwayat peminjaman
  Stream<List<Map<String, dynamic>>> borrowingsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('borrowings')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Map<String, dynamic>.from(d.data()))
              .toList();

          list.sort(
            (a, b) =>
                _waktu(b['borrow_date']).compareTo(_waktu(a['borrow_date'])),
          );

          return list;
        });
  }

  // Memperbarui foto barang lama di Firestore
  Future<void> updateDummyImages() async {
    for (final entry in _images.entries) {
      final result = await _items.where('code', isEqualTo: entry.key).get();

      for (final doc in result.docs) {
        await doc.reference.update({'image': entry.value});
      }
    }
  }

  // Menambahkan data dummy jika collection masih kosong
  Future<bool> seedDummyData() async {
    final cek = await _items.limit(1).get();

    if (cek.docs.isNotEmpty) return false;

    final data = <Map<String, String>>[
      {
        'item_name': 'Laptop Asus Vivobook',
        'category': 'Komputer',
        'code': 'LAB-KMP-001',
        'status': 'Available',
        'image': _images['LAB-KMP-001']!,
        'spesification': 'Intel Core i5, RAM 8GB, SSD 512GB, layar 14 inci',
      },
      {
        'item_name': 'PC Desktop Lenovo',
        'category': 'Komputer',
        'code': 'LAB-KMP-002',
        'status': 'Borrowed',
        'image': _images['LAB-KMP-002']!,
        'spesification': 'Intel Core i3, RAM 8GB, HDD 1TB, monitor 19 inci',
      },
      {
        'item_name': 'Router MikroTik RB951',
        'category': 'Jaringan',
        'code': 'LAB-JRG-001',
        'status': 'Available',
        'image': _images['LAB-JRG-001']!,
        'spesification': '5 port Ethernet, WiFi 2.4GHz, RouterOS L4',
      },
      {
        'item_name': 'Switch TP-Link 8 Port',
        'category': 'Jaringan',
        'code': 'LAB-JRG-002',
        'status': 'Available',
        'image': _images['LAB-JRG-002']!,
        'spesification': '8 port Gigabit, unmanaged, plug and play',
      },
      {
        'item_name': 'LAN Tester',
        'category': 'Jaringan',
        'code': 'LAB-JRG-003',
        'status': 'Borrowed',
        'image': _images['LAB-JRG-003']!,
        'spesification': 'Pengujian kabel RJ45 dan RJ11, indikator LED',
      },
      {
        'item_name': 'Arduino Uno R3',
        'category': 'Elektronik',
        'code': 'LAB-ELK-001',
        'status': 'Available',
        'image': _images['LAB-ELK-001']!,
        'spesification': 'ATmega328P, 14 pin digital, 6 pin analog, USB',
      },
      {
        'item_name': 'Raspberry Pi 4',
        'category': 'Elektronik',
        'code': 'LAB-ELK-002',
        'status': 'Available',
        'image': _images['LAB-ELK-002']!,
        'spesification': 'Quad-core 1.5GHz, RAM 4GB, WiFi, Bluetooth',
      },
      {
        'item_name': 'Multimeter Digital',
        'category': 'Alat Ukur',
        'code': 'LAB-UKR-001',
        'status': 'Available',
        'image': _images['LAB-UKR-001']!,
        'spesification': 'Mengukur tegangan, arus, dan hambatan, layar LCD',
      },
      {
        'item_name': 'Proyektor Epson',
        'category': 'Presentasi',
        'code': 'LAB-PRS-001',
        'status': 'Borrowed',
        'image': _images['LAB-PRS-001']!,
        'spesification': '3600 lumens, resolusi XGA, input HDMI dan VGA',
      },
    ];

    final batch = _db.batch();
    final now = DateTime.now();

    for (var i = 0; i < data.length; i++) {
      final ref = _items.doc();

      batch.set(ref, {
        'item_id': ref.id,
        ...data[i],
        'created_at': Timestamp.fromDate(now.subtract(Duration(minutes: i))),
      });
    }

    await batch.commit();
    return true;
  }
}
