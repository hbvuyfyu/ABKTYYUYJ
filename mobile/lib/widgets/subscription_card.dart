import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final int dailyUsed;
  final int dailyLimit;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.dailyUsed,
    required this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    final plan = subscription['plan'];
    final endDate = DateTime.tryParse(subscription['endDate'] ?? '');
    final daysLeft = endDate?.difference(DateTime.now()).inDays ?? 0;
    final progress = dailyLimit > 0 ? dailyUsed / dailyLimit : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('اشتراك نشط', style: TextStyle(color: AppTheme.success, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Text(plan?['nameAr'] ?? '', style: const TextStyle(color: AppTheme.accent, fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statItem('العمليات المستخدمة', '$dailyUsed', AppTheme.primary),
              _divider(),
              _statItem('الحد اليومي', '$dailyLimit', AppTheme.accent),
              _divider(),
              _statItem('أيام متبقية', '$daysLeft', daysLeft <= 2 ? AppTheme.error : AppTheme.success),
            ],
          ),
          const SizedBox(height: 16),
          const Text('الاستخدام اليومي', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? AppTheme.error : AppTheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$dailyUsed من $dailyLimit عملية', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: progress >= 1.0 ? AppTheme.error : AppTheme.primary, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (endDate != null) ...[
            const SizedBox(height: 12),
            Text('تاريخ الانتهاء: ${DateFormat('yyyy/MM/dd').format(endDate)}',
              style: const TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo', fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo')),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 11)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: AppTheme.border, margin: const EdgeInsets.symmetric(horizontal: 8));
  }
}
