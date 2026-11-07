import 'package:flutter/material.dart';

// Küçük, renkli durum rozeti.
// Metin ve renkler dışarıdan verildiği için farklı ekranlarda
// (bağlantı durumu, ileride görev durumları) tekrar kullanılabilir.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}