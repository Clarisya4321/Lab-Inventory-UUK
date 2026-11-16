import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Warna-warna utama aplikasi (dipakai di semua halaman agar konsisten).
class AppColors {
  static const Color primary = Color(0xFF3157D5);
  static const Color accent = Color(0xFFFF8A3D);
  static const Color purple = Color(0xFF7C5CFC);
  static const Color available = Color(0xFF22B07D);
  static const Color borrowed = Color(0xFFF0594F);
  static const Color background = Color(0xFFF4F6FC);
  static const Color text = Color(0xFF1F2A44);
  static const Color muted = Color(0xFF6B7694);
}

const LinearGradient appGradient = LinearGradient(
  colors: [AppColors.primary, AppColors.purple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const List<String> kCategories = [
  'Komputer',
  'Jaringan',
  'Elektronik',
  'Alat Ukur',
  'Presentasi',
];

IconData categoryIcon(String c) {
  switch (c) {
    case 'Komputer':
      return Icons.laptop_mac_rounded;
    case 'Jaringan':
      return Icons.router_rounded;
    case 'Elektronik':
      return Icons.memory_rounded;
    case 'Alat Ukur':
      return Icons.speed_rounded;
    case 'Presentasi':
      return Icons.slideshow_rounded;
    default:
      return Icons.science_rounded;
  }
}

Color categoryColor(String c) {
  switch (c) {
    case 'Komputer':
      return AppColors.primary;
    case 'Jaringan':
      return AppColors.purple;
    case 'Elektronik':
      return AppColors.accent;
    case 'Alat Ukur':
      return const Color(0xFF14A3C7);
    case 'Presentasi':
      return const Color(0xFFE5528A);
    default:
      return AppColors.muted;
  }
}

Color statusColor(String s) =>
    s == 'Borrowed' ? AppColors.borrowed : AppColors.available;

String formatTanggal(dynamic value) {
  if (value is! Timestamp) return '-';
  final d = value.toDate();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Dekorasi standar untuk semua kolom input.
InputDecoration appInput(String label, IconData icon, {Widget? suffix}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    border: border(const Color(0xFFDDE3F3)),
    enabledBorder: border(const Color(0xFFDDE3F3)),
    focusedBorder: border(AppColors.primary, 1.8),
    errorBorder: border(AppColors.borrowed),
    focusedErrorBorder: border(AppColors.borrowed, 1.8),
  );
}

/// Kepala berwarna untuk halaman Login dan Register.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + (showBack ? 8 : 40), 24, 40),
      decoration: const BoxDecoration(
        gradient: appGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          const CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(Icons.science_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
