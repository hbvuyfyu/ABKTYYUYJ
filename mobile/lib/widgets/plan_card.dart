import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isPopular;
  final VoidCallback onSelect;

  const PlanCard({super.key, required this.plan, this.isPopular = false, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPopular
                  ? [const Color(0xFF2A2A2A), const Color(0xFF0A0A0A)]
                  : [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPopular ? AppTheme.primary : AppTheme.border,
              width: isPopular ? 1.5 : 1,
            ),
            boxShadow: isPopular
                ? [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 8))]
                : [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan['nameAr'] ?? plan['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
                        const SizedBox(height: 4),
                        Text('${plan['durationDays']} يوم', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${plan['price']}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Cairo')),
                      const Text('لمرة واحدة', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 12),
              _featureRow(Icons.bolt_outlined, '${plan['dailyOperations']} عملية يومياً'),
              const SizedBox(height: 8),
              _featureRow(Icons.calendar_today_outlined, 'صالح ${plan['durationDays']} يوم'),
              const SizedBox(height: 8),
              _featureRow(Icons.refresh, 'إعادة ضبط يومي تلقائي'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? AppTheme.primary : AppTheme.surfaceVariant,
                    foregroundColor: isPopular ? Colors.black : AppTheme.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('اختر هذه الباقة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: isPopular ? Colors.black : AppTheme.textPrimary)),
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('الأكثر شيوعاً', style: TextStyle(color: Colors.black, fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 14)),
      ],
    );
  }
}
