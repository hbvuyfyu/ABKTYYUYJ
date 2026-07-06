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
  String _selectedGroup = 'payment'; // payment, cloudinary, blockchain, general

  final Map<String, String> _settingLabels = {
    'sham_cash_number': 'رقم Sham Cash',
    'sham_cash_account_address': 'عنوان حساب ShamCash (لـ API Syria)',
    'syriatel_cash_number': 'رقم Syriatel Cash (كود)',
    'syriatel_cash_gsm': 'رقم Syriatel Cash للموبايل',
    'usdt_bep20_address': 'عنوان USDT BEP20',
    'oxapay_merchant_api_key': 'مفتاح OxaPay API',
    'api_syria_api_key': 'مفتاح API Syria',
    'api_syria_account_address': 'عنوان حساب API Syria',
    'syria_usd_to_sp_rate': 'سعر صرف الدولار (ليرة)',
    'cloudinary_cloud_name': 'Cloudinary Cloud Name',
    'cloudinary_api_key': 'Cloudinary API Key',
    'cloudinary_api_secret': 'Cloudinary API Secret',
    'bscscan_api_key': 'BSCScan API Key (للتحقق من TXID)',
    'usdt_contract_address': 'عنوان عقد USDT',
  };

  final Map<String, String> _groupLabels = {
    'payment': 'إعدادات الدفع',
    'cloudinary': 'Cloudinary (رفع الصور)',
    'blockchain': 'البلوكشين',
    'general': 'عام',
  };

  final List<String> _groupOrder = ['payment', 'cloudinary', 'blockchain', 'general'];

  @override
  void initState() { super.initState(); _loadSettings(); }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

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
      final settingsList = _settings.map((s) {
        final key = s['key'] as String;
        return {
          'key': key,
          'value': _controllers[key]?.text ?? s['value'],
          'group': s['group'] ?? 'general',
        };
      }).toList();
      final res = await ApiService.put('/settings/bulk', {'settings': settingsList});
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ الإعدادات', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']?.toString() ?? 'فشل الحفظ', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('فشل الحفظ', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
      ));
    }
    setState(() => _saving = false);
  }

  List<String> _getKeysForGroup(String group) {
    return _settings
        .where((s) => (s['group'] as String?) == group)
        .map((s) => s['key'] as String)
        .toList();
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Group tabs
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _groupOrder.map((group) {
                            final isSelected = _selectedGroup == group;
                            final count = _getKeysForGroup(group).length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  '${_groupLabels[group] ?? group} ($count)',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedGroup = group),
                                selectedColor: AppTheme.primary,
                                backgroundColor: AppTheme.surfaceVariant,
                                checkmarkColor: Colors.transparent,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const Divider(color: AppTheme.border, height: 1),
                    // Settings list
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _groupLabels[_selectedGroup] ?? _selectedGroup,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._getKeysForGroup(_selectedGroup).map((key) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextField(
                                controller: _controllers[key],
                                obscureText: key.toLowerCase().contains('secret') || key.toLowerCase().contains('key'),
                                decoration: InputDecoration(
                                  labelText: _settingLabels[key] ?? key,
                                  helperText: key.contains('secret') || key.contains('key')
                                      ? 'يُحفظ بشكل آمن'
                                      : null,
                                  helperStyle: const TextStyle(color: AppTheme.textHint, fontSize: 11),
                                ),
                              ),
                            )),
                            if (_getKeysForGroup(_selectedGroup).isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'لا توجد إعدادات في هذه المجموعة',
                                    style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            GradientButton(
                              onPressed: _saving ? null : _saveAll,
                              isLoading: _saving,
                              text: 'حفظ الإعدادات',
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
