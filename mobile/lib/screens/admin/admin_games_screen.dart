import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminGamesScreen extends StatefulWidget {
  const AdminGamesScreen({super.key});
  @override
  State<AdminGamesScreen> createState() => _AdminGamesScreenState();
}

class _AdminGamesScreenState extends State<AdminGamesScreen> {
  List<dynamic> _games = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadGames(); }

  Future<void> _loadGames() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/games');
      if (res['success'] == true) {
        setState(() => _games = (res['data'] as List?) ?? []);
      } else {
        setState(() => _error = res['message']?.toString() ?? 'فشل تحميل الألعاب');
      }
    } catch (_) {
      setState(() => _error = 'خطأ في الاتصال بالسيرفر');
    }
    setState(() => _loading = false);
  }

  // ── Add / Edit Game dialog ─────────────────────────────────────────────────
  void _showGameDialog({Map<String, dynamic>? game}) {
    final isEdit = game != null;
    final nameCtrl        = TextEditingController(text: game?['name'] ?? '');
    final displayCtrl     = TextEditingController(text: game?['displayName'] ?? '');
    final packageCtrl     = TextEditingController(text: game?['package'] ?? '');
    final devKeyCtrl      = TextEditingController(text: game?['devKey'] ?? '');
    final appKeyCtrl      = TextEditingController(text: game?['appKey'] ?? '');
    final appTokenCtrl    = TextEditingController(text: game?['appToken'] ?? '');
    final emojiCtrl       = TextEditingController(text: game?['emoji'] ?? '🎮');
    String platform       = game?['platform'] ?? 'af';
    bool isActive         = game?['isActive'] != false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'تعديل: ${game!['displayName']}' : '➕ إضافة لعبة جديدة',
          style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Platform picker
            const Align(alignment: Alignment.centerLeft,
                child: Text('المنصة', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13))),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'af',       label: Text('AppsFlyer', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                ButtonSegment(value: 'singular',  label: Text('Singular',  style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                ButtonSegment(value: 'adj',       label: Text('Adjust',    style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
              ],
              selected: {platform},
              onSelectionChanged: (s) => setS(() => platform = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? AppTheme.primary.withOpacity(0.2) : Colors.transparent),
              ),
            ),
            const SizedBox(height: 14),
            _field(nameCtrl,     'الاسم الداخلي (EN)', 'dice_dream'),
            const SizedBox(height: 10),
            _field(displayCtrl,  'اسم العرض (للمستخدم)', 'Dice Dreams'),
            const SizedBox(height: 10),
            _field(emojiCtrl,    'الإيموجي', '🎲'),
            const SizedBox(height: 10),
            if (platform != 'adj') ...[
              _field(packageCtrl, 'Package Name', 'com.example.game'),
              const SizedBox(height: 10),
            ],
            if (platform == 'af')   _field(devKeyCtrl,   'Dev Key (AppsFlyer)', 'Hn5qYjVAa...'),
            if (platform == 'singular') _field(appKeyCtrl, 'App Key (Singular)',  'myapp_key_xxxx'),
            if (platform == 'adj')  _field(appTokenCtrl, 'App Token (Adjust)',   '367kicwptj5s'),
            const SizedBox(height: 10),
            if (isEdit) SwitchListTile(
              value: isActive,
              onChanged: (v) => setS(() => isActive = v),
              title: const Text('مفعّل', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary, fontSize: 14)),
              activeColor: AppTheme.success,
              tileColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
            ),
          ])),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final body = <String, dynamic>{
                'name': nameCtrl.text.trim(),
                'displayName': displayCtrl.text.trim(),
                'platform': platform,
                'emoji': emojiCtrl.text.trim(),
              };
              if (platform != 'adj') body['package'] = packageCtrl.text.trim();
              if (platform == 'af')       body['devKey']   = devKeyCtrl.text.trim();
              if (platform == 'singular') body['appKey']   = appKeyCtrl.text.trim();
              if (platform == 'adj')      body['appToken'] = appTokenCtrl.text.trim();
              if (isEdit)                 body['isActive'] = isActive;

              if (body['name'].toString().isEmpty || body['displayName'].toString().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاسم مطلوب', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.error));
                return;
              }

              Navigator.pop(context);
              try {
                final res = isEdit
                    ? await ApiService.put('/admin/games/${game!['id']}', body)
                    : await ApiService.post('/admin/games', body);
                if (!mounted) return;
                if (res['success'] == true) {
                  _showSnack(isEdit ? 'تم تحديث اللعبة ✓' : 'تم إضافة اللعبة ✓', AppTheme.success);
                  _loadGames();
                } else {
                  _showSnack(res['message']?.toString() ?? 'فشل', AppTheme.error);
                }
              } catch (_) { _showSnack('خطأ في الاتصال', AppTheme.error); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(isEdit ? 'حفظ' : 'إضافة', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      )),
    );
  }

  // ── Add Event dialog ───────────────────────────────────────────────────────
  void _showAddEventDialog(Map<String, dynamic> game) {
    final evNameCtrl    = TextEditingController();
    final evDisplayCtrl = TextEditingController();
    final evTokenCtrl   = TextEditingController();
    bool isPurchase = false;
    final platform = game['platform'] as String? ?? 'af';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('➕ إضافة حدث لـ ${game['displayName']}',
            style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary, fontSize: 15)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(evNameCtrl,    'اسم الحدث (يُرسل للـ API)', 'level_completed'),
          const SizedBox(height: 10),
          _field(evDisplayCtrl, 'اسم العرض (للمستخدم)',      'Level Completed'),
          if (platform == 'adj') ...[
            const SizedBox(height: 10),
            _field(evTokenCtrl, 'Event Token (Adjust)', 'abc123'),
          ],
          const SizedBox(height: 10),
          SwitchListTile(
            value: isPurchase,
            onChanged: (v) => setS(() => isPurchase = v),
            title: const Text('حدث شراء (purchase)', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary, fontSize: 13)),
            activeColor: AppTheme.warning,
            tileColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (evNameCtrl.text.trim().isEmpty || evDisplayCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاسم مطلوب'), backgroundColor: AppTheme.error));
                return;
              }
              Navigator.pop(context);
              try {
                final res = await ApiService.post('/admin/games/${game['id']}/events', {
                  'eventName': evNameCtrl.text.trim(),
                  'displayName': evDisplayCtrl.text.trim(),
                  'eventToken': evTokenCtrl.text.trim(),
                  'isPurchase': isPurchase,
                });
                if (!mounted) return;
                if (res['success'] == true) {
                  _showSnack('تم إضافة الحدث ✓', AppTheme.success);
                  _loadGames();
                } else {
                  _showSnack(res['message']?.toString() ?? 'فشل', AppTheme.error);
                }
              } catch (_) { _showSnack('خطأ في الاتصال', AppTheme.error); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      )),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      final res = await ApiService.delete('/admin/games/events/$eventId');
      if (!mounted) return;
      if (res['success'] == true) { _showSnack('تم حذف الحدث', AppTheme.success); _loadGames(); }
      else _showSnack('فشل حذف الحدث', AppTheme.error);
    } catch (_) { _showSnack('خطأ في الاتصال', AppTheme.error); }
  }

  Future<void> _deleteGame(String gameId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary)),
        content: const Text('هل تريد إلغاء تفعيل هذه اللعبة؟', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo'))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ApiService.delete('/admin/games/$gameId');
    if (!mounted) return;
    if (res['success'] == true) { _showSnack('تم حذف اللعبة', AppTheme.success); _loadGames(); }
    else _showSnack('فشل', AppTheme.error);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: color,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الألعاب', style: TextStyle(fontFamily: 'Cairo')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.accent), onPressed: () => _showGameDialog()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadGames, child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo'))),
                ]))
              : _games.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.gamepad_outlined, color: AppTheme.textHint, size: 64),
                      const SizedBox(height: 16),
                      const Text('لا توجد ألعاب مضافة بعد', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: () => _showGameDialog(), icon: const Icon(Icons.add), label: const Text('إضافة لعبة', style: TextStyle(fontFamily: 'Cairo'))),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadGames,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _games.length,
                        itemBuilder: (_, i) => _buildGameCard(_games[i] as Map<String, dynamic>),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGameDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('لعبة جديدة', style: TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> g) {
    final events = (g['events'] as List?) ?? [];
    final platform = g['platform'] as String? ?? '';
    final platformColors = {'af': const Color(0xFF0066CC), 'singular': const Color(0xFF9900CC), 'adj': const Color(0xFFCC6600)};
    final platformLabels = {'af': 'AppsFlyer', 'singular': 'Singular', 'adj': 'Adjust'};
    final pColor = platformColors[platform] ?? Colors.grey;
    final isActive = g['isActive'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Text(g['emoji'] ?? '🎮', style: const TextStyle(fontSize: 28)),
        title: Row(children: [
          Expanded(child: Text(g['displayName'] ?? '', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: pColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: pColor.withOpacity(0.5))),
            child: Text(platformLabels[platform] ?? platform, style: TextStyle(color: pColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: isActive ? AppTheme.success.withOpacity(0.15) : AppTheme.error.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(isActive ? '✓' : '✗', style: TextStyle(color: isActive ? AppTheme.success : AppTheme.error, fontSize: 11)),
          ),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (g['package'] != null && g['package'].toString().isNotEmpty)
            Text(g['package'] ?? '', style: const TextStyle(color: AppTheme.textHint, fontFamily: 'Courier', fontSize: 10)),
          Text('${events.length} حدث', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 11)),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20), onPressed: () => _showGameDialog(game: g)),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), onPressed: () => _deleteGame(g['id'])),
        ]),
        children: [
          // Events list
          if (events.isNotEmpty) ...[
            const Divider(color: AppTheme.border),
            const Align(alignment: Alignment.centerLeft,
                child: Text('الأحداث:', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary, fontSize: 12))),
            const SizedBox(height: 6),
            ...events.map((e) {
              final ev = e as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.bolt, color: AppTheme.accent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ev['displayName'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', fontSize: 12)),
                    Text(ev['eventName'] ?? '', style: const TextStyle(color: AppTheme.textHint, fontFamily: 'Courier', fontSize: 10)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.error, size: 16),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    onPressed: () => _deleteEvent(ev['id']),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddEventDialog(g),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة حدث', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accent, side: const BorderSide(color: AppTheme.accent), minimumSize: const Size(0, 40)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', fontSize: 14),
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      labelStyle: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 12),
    ),
  );
}
