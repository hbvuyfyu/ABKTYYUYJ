import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/plan_card.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadPlans(); }

  Future<void> _loadPlans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/plans', auth: false);
      if (res['success'] == true) {
        setState(() { _plans = (res['data'] as List?) ?? []; _loading = false; });
      } else {
        setState(() { _error = res['message']?.toString() ?? 'فشل تحميل الباقات'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'خطأ في الاتصال بالسيرفر'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('باقات الاشتراك'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadPlans, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('اختر الباقة المناسبة لك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    const Text('اشتراك واحد نشط فقط في كل مرة', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                    const SizedBox(height: 24),
                    ..._plans.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlanCard(
                        plan: e.value as Map<String, dynamic>,
                        isPopular: e.key == 1,
                        onSelect: () => context.push('/payment/${(e.value as Map)['id']}'),
                      ),
                    )),
                  ]),
                ),
    );
  }
}
