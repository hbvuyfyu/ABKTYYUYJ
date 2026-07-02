import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  List<dynamic> _settings = [];
  bool _loading = true;
  String? _error;
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() { super.initState(); _loadSettings(); }
  @override
  void dispose() { _controllers.forEach((_, c) => c.dispose()); super.dispose(); }

  Future<void> _loadSettings() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/settings');
      if (res['success'] == true) {
        _settings = (res['data'] as List?) ?? [];
        for (final s in _settings) {
          final key = s['key'] as String;
          _controllers[key] = TextEditingController(text: s['value'] as String? ?? '');
        }
        setState(() {});
      } else {
        setState(() => _error = res['message']?.toString() ?? 'فشل تحميل الإعدادات');
      }
    } catch (_) {
      setState(() => _error = 'خطأ في الاتصال بالسيرفر');
    }
    setState(() => _loading = false);
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final settingsList = _settings.map((s) => {
        'key': s['key'],
        'value': _controllers[s['key']]?.text ?? s['value'],
        'group': s['group'] ?? 'general',
      }).toList();
      final res = await ApiService.put('/settings/bulk', {'settings': settingsList});
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? 'فشل الحفظ', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الحفظ', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadSettings, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ..._settings.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: _controllers[s['key']],
                        decoration: InputDecoration(labelText: s['key'] as String),
                      ),
                    )),
                    if (_settings.isEmpty)
                      const Center(child: Text('لا توجد إعدادات بعد', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'))),
                    if (_settings.isNotEmpty)
                      GradientButton(onPressed: _saving ? null : _saveAll, isLoading: _saving, text: 'حفظ الإعدادات'),
                  ]),
                ),
    );
  }
}
