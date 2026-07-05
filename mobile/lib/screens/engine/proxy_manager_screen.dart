import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProxyManagerScreen extends StatefulWidget {
  const ProxyManagerScreen({super.key});
  @override
  State<ProxyManagerScreen> createState() => _ProxyManagerScreenState();
}

class _ProxyManagerScreenState extends State<ProxyManagerScreen> {
  List<Map<String, dynamic>> _proxies = [];
  String? _selectedProxyId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/proxies');
      if (res['success'] == true) {
        _proxies = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _selectedProxyId = res['selectedProxyId'] as String?;
      } else {
        _error = res['message']?.toString() ?? 'فشل التحميل';
      }
    } catch (e) {
      _error = 'خطأ: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addProxy() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const _ProxyEditScreen()),
    );
    if (result != null) {
      await _load();
    }
  }

  Future<void> _editProxy(Map<String, dynamic> proxy) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => _ProxyEditScreen(proxy: proxy)),
    );
    if (result != null) {
      await _load();
    }
  }

  Future<void> _testProxy(Map<String, dynamic> proxy) async {
    final id = proxy['id'] as String;
    // Optimistic UI
    setState(() {
      final idx = _proxies.indexWhere((p) => p['id'] == id);
      if (idx >= 0) _proxies[idx]['_testing'] = true;
    });

    try {
      final res = await ApiService.post('/proxies/$id/test', {});
      if (!mounted) return;
      if (res['success'] == true) {
        final ip = res['ip']?.toString() ?? '';
        final latency = res['latencyMs']?.toString() ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('البروكسي يعمل بنجاح\nIP: $ip · زمن الاستجابة: ${latency}ms',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'البروكسي لا يعمل',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      final idx = _proxies.indexWhere((p) => p['id'] == id);
      if (idx >= 0) _proxies[idx]['_testing'] = false;
    });
    await _load();
  }

  Future<void> _selectProxy(Map<String, dynamic> proxy) async {
    final id = proxy['id'] as String;
    try {
      final res = await ApiService.post('/proxies/$id/select', {});
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختيار البروكسي: ${proxy['name']}',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'فشل التحديد',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearSelection() async {
    try {
      final res = await ApiService.post('/proxies/clear-selection', {});
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إلغاء اختيار البروكسي — سيعمل التطبيق باتصال مباشر',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteProxy(Map<String, dynamic> proxy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('تأكيد الحذف',
            style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
        content: Text('هل تريد حذف البروكسي "${proxy['name']}"؟',
            style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.delete('/proxies/${proxy['id']}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف البروكسي', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('إدارة البروكسي',
            style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('إعادة')),
                  ]),
                ))
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: _proxies.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 100),
                          Center(child: Column(children: [
                            const Icon(Icons.cloud_off, color: AppTheme.textHint, size: 64),
                            const SizedBox(height: 16),
                            const Text('لا توجد بروكسيات مضافة',
                                style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                            const SizedBox(height: 8),
                            const Text('اضغط على زر + لإضافة بروكسي جديد',
                                style: TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo', fontSize: 12)),
                          ])),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                          itemCount: _proxies.length,
                          itemBuilder: (_, i) => _proxyCard(_proxies[i]),
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProxy,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _proxyCard(Map<String, dynamic> p) {
    final id = p['id'] as String;
    final name = p['name']?.toString() ?? '';
    final type = p['type']?.toString() ?? 'socks5';
    final host = p['host']?.toString() ?? '';
    final port = p['port']?.toString() ?? '';
    final hasAuth = (p['username'] as String?)?.isNotEmpty == true;
    final isWorking = p['isWorking'] == true;
    final isActive = p['isActive'] == true;
    final testing = p['_testing'] == true;
    final isSelected = _selectedProxyId == id;

    final typeIcon = type == 'socks5' ? Icons.security : Icons.language;
    final typeLabel = type == 'socks5' ? 'SOCKS5' : 'HTTP';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (isSelected ? AppTheme.primary : AppTheme.surfaceVariant).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(typeIcon,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(name,
                    style: const TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary, fontSize: 15)),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('مختار',
                        style: TextStyle(color: AppTheme.primary, fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text('$typeLabel · $host:$port',
                  style: const TextStyle(color: AppTheme.textHint, fontFamily: 'monospace', fontSize: 11)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                _statusChip(
                  testing ? 'فحص...' : (isWorking ? 'يعمل' : 'لا يعمل'),
                  testing ? AppTheme.warning : (isWorking ? AppTheme.success : AppTheme.error),
                ),
                if (hasAuth)
                  _statusChip('محمي بكلمة مرور', AppTheme.primary),
                if (!isActive)
                  _statusChip('معطّل', AppTheme.textSecondary),
              ]),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: testing ? null : () => _testProxy(p),
                icon: testing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.warning))
                    : const Icon(Icons.wifi_find, size: 16, color: AppTheme.textSecondary),
                label: const Text('تحقق', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editProxy(p),
                icon: const Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
                label: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _deleteProxy(p),
                icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                label: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ),
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _selectProxy(p),
                icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.black),
                label: const Text('اختيار هذا البروكسي',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Add/Edit proxy screen ─────────────────────────────────────────────────────

class _ProxyEditScreen extends StatefulWidget {
  final Map<String, dynamic>? proxy;
  const _ProxyEditScreen({this.proxy});
  @override
  State<_ProxyEditScreen> createState() => _ProxyEditScreenState();
}

class _ProxyEditScreenState extends State<_ProxyEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _type = 'socks5';
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.proxy != null) {
      final p = widget.proxy!;
      _nameCtrl.text = p['name']?.toString() ?? '';
      _hostCtrl.text = p['host']?.toString() ?? '';
      _portCtrl.text = p['port']?.toString() ?? '';
      _usernameCtrl.text = p['username']?.toString() ?? '';
      _passwordCtrl.text = p['password']?.toString() ?? '';
      _type = p['type']?.toString() ?? 'socks5';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'host': _hostCtrl.text.trim(),
      'port': int.tryParse(_portCtrl.text.trim()) ?? 0,
      'username': _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
    };

    try {
      final res = widget.proxy == null
          ? await ApiService.post('/proxies', body)
          : await ApiService.put('/proxies/${widget.proxy!['id']}', body);
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pop(context, res['data']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'فشل الحفظ',
                style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.proxy != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(isEdit ? 'تعديل البروكسي' : 'إضافة بروكسي',
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Type selector
            const Text('نوع البروكسي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _typeCard('socks5', 'SOCKS5', Icons.security)),
              const SizedBox(width: 12),
              Expanded(child: _typeCard('http', 'HTTP', Icons.language)),
            ]),
            const SizedBox(height: 20),

            _field(
              controller: _nameCtrl,
              label: 'اسم البروكسي',
              hint: 'مثال: بروكسي العمل',
              icon: Icons.label_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 14),

            _field(
              controller: _hostCtrl,
              label: 'المضيف (Host)',
              hint: 'مثال: 127.0.0.1',
              icon: Icons.dns_outlined,
              keyboardType: TextInputType.text,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'المضيف مطلوب' : null,
            ),
            const SizedBox(height: 14),

            _field(
              controller: _portCtrl,
              label: 'المنفذ (Port)',
              hint: 'مثال: 1080',
              icon: Icons.numbers,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'المنفذ مطلوب';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0 || n > 65535) return 'منفذ غير صحيح (1-65535)';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Auth section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.lock_outline, color: AppTheme.primary, size: 17),
                  const SizedBox(width: 8),
                  const Text('المصادقة (اختياري)',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
                ]),
                const SizedBox(height: 4),
                const Text('اتركها فارغة إذا كان البروكسي لا يتطلب اسم مستخدم وكلمة مرور',
                    style: TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo', fontSize: 11)),
                const SizedBox(height: 12),
                _field(
                  controller: _usernameCtrl,
                  label: 'اسم المستخدم',
                  hint: 'username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _passwordCtrl,
                  label: 'كلمة المرور',
                  hint: 'password',
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textHint, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Icon(isEdit ? Icons.check : Icons.add, color: Colors.black),
              label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة البروكسي',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _typeCard(String value, String label, IconData icon) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.12) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo', fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
