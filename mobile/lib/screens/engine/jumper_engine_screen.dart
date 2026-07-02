import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

enum _Phase {
  idle,
  loadingApps,
  detecting,
  pickEvent,
  sending,
  done,
}

class JumperEngineScreen extends StatefulWidget {
  const JumperEngineScreen({super.key});
  @override
  State<JumperEngineScreen> createState() => _JumperEngineScreenState();
}

class _JumperEngineScreenState extends State<JumperEngineScreen> with SingleTickerProviderStateMixin {
  static const _ch = MethodChannel('com.vip.app/jumper');

  _Phase _phase = _Phase.idle;
  final List<String> _log = [];

  Map<String, dynamic>? _game;
  String? _platform;
  List<Map<String, dynamic>> _events = [];

  String _gaid  = '';
  String _afUid = '';

  final _gaidCtrl  = TextEditingController();
  final _afUidCtrl = TextEditingController();
  bool _showManualGaid  = false;
  bool _showManualAfUid = false;

  Map<String, dynamic>? _selectedEvent;
  bool _customLevel        = false;
  final _customLevelCtrl   = TextEditingController();

  bool   _resultOk     = false;
  String _resultMsg    = '';
  int?   _resultHttp;

  Map<String, dynamic>? _dailyUsage;

  late final AnimationController _logoCtrl;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _loadDailyUsage();
  }

  @override
  void dispose() {
    _gaidCtrl.dispose();
    _afUidCtrl.dispose();
    _customLevelCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  void _log$(String msg) {
    if (!mounted) return;
    final t = DateTime.now();
    final ts = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:${t.second.toString().padLeft(2,'0')}';
    setState(() => _log.add('[$ts] $msg'));
  }

  Future<void> _loadDailyUsage() async {
    try {
      final res = await ApiService.get('/games/daily-usage');
      if (res['success'] == true && mounted) {
        setState(() => _dailyUsage = res['data'] as Map<String, dynamic>?);
      }
    } catch (_) {}
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _phase           = _Phase.idle;
      _log.clear();
      _game            = null;
      _platform        = null;
      _events          = [];
      _gaid            = '';
      _afUid           = '';
      _showManualGaid  = false;
      _showManualAfUid = false;
      _selectedEvent   = null;
      _customLevel     = false;
      _resultOk        = false;
      _resultMsg       = '';
      _resultHttp      = null;
    });
    _loadDailyUsage();
  }

  Future<void> _startFlow() async {
    setState(() { _phase = _Phase.loadingApps; _log.clear(); });
    _log$('جاري تحميل التطبيقات المفتوحة...');

    try {
      final raw  = await _ch.invokeMethod<List>('getRunningApps') ?? [];
      final apps = raw
          .map<Map<String, dynamic>>((a) => Map<String, dynamic>.from(a as Map))
          .where((a) => (a['name'] ?? a['label'] ?? '').toString().isNotEmpty)
          .toList()
        ..sort((a, b) => (a['name'] ?? a['label'] ?? '').toString().toLowerCase()
            .compareTo((b['name'] ?? b['label'] ?? '').toString().toLowerCase()));

      if (!mounted) return;

      if (apps.isEmpty) {
        _log$('لا توجد تطبيقات مفتوحة حالياً');
        setState(() => _phase = _Phase.idle);
        return;
      }

      _log$('${apps.length} تطبيق مفتوح');
      _showAppPicker(apps);
    } catch (e) {
      _log$('خطأ: $e');
      if (mounted) setState(() => _phase = _Phase.idle);
    }
  }

  void _showAppPicker(List<Map<String, dynamic>> apps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AppPickerSheet(apps: apps),
    ).then((picked) {
      if (!mounted) return;
      if (picked == null) {
        setState(() => _phase = _Phase.idle);
        return;
      }
      _onAppPicked(picked as Map<String, dynamic>);
    });
  }

  Future<void> _onAppPicked(Map<String, dynamic> app) async {
    final pkg = app['package'] as String? ?? '';
    setState(() => _phase = _Phase.detecting);
    _log$('اخترت: ${app['name'] ?? app['label'] ?? pkg}');
    _log$('Package: $pkg');

    final results = await Future.wait([
      _detectGame(pkg),
      _extractIds(pkg),
    ]);

    final detected = results[0] as Map<String, dynamic>?;
    if (!mounted) return;

    if (detected == null) {
      setState(() => _phase = _Phase.idle);
      return;
    }

    _game     = detected['game']     as Map<String, dynamic>?;
    _platform = detected['platform'] as String?;
    _events   = (detected['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    _selectedEvent = _events.isNotEmpty ? _events.first : null;
    _customLevel   = false;

    _showManualGaid  = _gaid.isEmpty;
    _showManualAfUid = _afUid.isEmpty && (_platform == 'af' || _platform == 'singular');

    setState(() => _phase = _Phase.pickEvent);
  }

  Future<Map<String, dynamic>?> _detectGame(String pkg) async {
    try {
      _log$('كشف المنصة من قاعدة البيانات...');
      final res = await ApiService.get('/games/detect?package=${Uri.encodeComponent(pkg)}', auth: false);
      if (res['found'] == true) {
        final platform = res['platform'] as String?;
        final game     = res['game']     as Map<String, dynamic>?;
        final events   = (game?['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _log$('اللعبة: ${game?['displayName']} [${_platformLabel(platform)}]');
        _log$('${events.length} حدث متاح');
        return {'platform': platform, 'game': game, 'events': events};
      } else {
        _log$('هذه اللعبة غير مدعومة في قاعدة البيانات');
        if (mounted) setState(() => _phase = _Phase.idle);
        return null;
      }
    } catch (e) {
      _log$('خطأ اتصال: $e');
      if (mounted) setState(() => _phase = _Phase.idle);
      return null;
    }
  }

  Future<void> _extractIds(String pkg) async {
    try {
      _log$('استخراج معرفات الجهاز...');
      final ids = await _ch.invokeMethod<Map>('getDeviceIds', {'packageName': pkg}) ?? {};
      _gaid  = ids['gaid']?.toString()  ?? '';
      _afUid = ids['afUid']?.toString() ?? '';
      if (_gaid.isNotEmpty) _log$('GAID: ${_masked(_gaid)}');
      else                   _log$('GAID: لم يتم الحصول عليه تلقائياً');
      if (_afUid.isNotEmpty) _log$('AF UID: ${_masked(_afUid)}');
      else                   _log_('AF UID: لم يتم الحصول عليه تلقائياً');
    } catch (e) {
      _log$('استخراج IDs: $e');
    }
  }

  void _log_(String msg) => _log$(msg);

  Future<void> _sendEvent() async {
    final game     = _game!;
    final platform = _platform!;

    final gaid  = _gaid.isNotEmpty  ? _gaid  : _gaidCtrl.text.trim();
    final afUid = _afUid.isNotEmpty ? _afUid : _afUidCtrl.text.trim();

    if (gaid.isEmpty) {
      _showSnack('أدخل GAID يدوياً أولاً');
      return;
    }
    if (platform == 'af' && afUid.isEmpty) {
      _showSnack('أدخل AF UID يدوياً أولاً');
      return;
    }

    String eventName  = '';
    String eventToken = '';

    if (_customLevel) {
      final lvlStr = _customLevelCtrl.text.trim();
      final lvl    = int.tryParse(lvlStr);
      if (lvl == null || lvl <= 0) {
        _showSnack('أدخل رقم لفل صحيح (مثال: 5)');
        return;
      }
      eventName  = _buildCustomLevelEvent(game, platform, lvl);
      eventToken = _buildCustomLevelToken(game, platform, lvl);
      _log$('لفل مخصص: $eventName');
    } else {
      if (_selectedEvent == null) { _showSnack('اختر حدثاً أولاً'); return; }
      eventName  = _selectedEvent!['eventName']  as String? ?? '';
      eventToken = _selectedEvent!['eventToken'] as String? ?? '';
    }

    setState(() { _phase = _Phase.sending; });
    _log_('إرسال: $eventName...');

    final body = <String, dynamic>{ 'platform': platform, 'gaid': gaid };
    if (afUid.isNotEmpty) body['afUid'] = afUid;

    switch (platform) {
      case 'af':
        body['package']   = game['package'];
        body['devKey']    = game['devKey'];
        body['eventName'] = eventName;
      case 'adj':
        body['appToken']   = game['appToken'];
        body['eventToken'] = eventToken.isNotEmpty ? eventToken : eventName;
      case 'singular':
        body['package']   = game['package'];
        body['appKey']    = game['appKey'];
        body['eventName'] = eventName;
    }

    try {
      final res  = await ApiService.post('/games/send-event', body);
      final sc   = res['_statusCode'] as int? ?? res['statusCode'] as int? ?? 0;
      final code = res['code'] as String? ?? '';

      if (sc == 403 || sc == 401 || sc == 429) {
        String msg;
        if (code == 'NO_SUBSCRIPTION')     msg = 'لا يوجد اشتراك نشط. اشترك في باقة أولاً.';
        else if (code == 'DAILY_LIMIT_EXCEEDED') msg = 'وصلت للحد اليومي (${res['limit']} عملية). حاول غداً.';
        else                                msg = 'خطأ مصادقة. يرجى إعادة تسجيل الدخول.';
        _log$(msg);
        setState(() { _phase = _Phase.pickEvent; });
        _showSnack(msg);
        return;
      }

      final ok = res['success'] == true;
      final httpCode = res['statusCode'] as int? ?? sc;
      _log$(ok ? 'نجح الإرسال - HTTP $httpCode' : 'فشل: ${res['message'] ?? 'خطأ'}');

      if (ok) {
        final usage     = res['dailyUsage'] as Map<String, dynamic>?;
        final remaining = usage?['remaining'];
        if (remaining != null) _log$('عمليات متبقية اليوم: $remaining');
      }

      await _loadDailyUsage();
      setState(() {
        _phase      = _Phase.done;
        _resultOk   = ok;
        _resultMsg  = ok ? 'تم إرسال الحدث بنجاح!' : 'فشل الإرسال';
        _resultHttp = httpCode;
      });
    } catch (e) {
      _log$('خطأ شبكة: $e');
      setState(() { _phase = _Phase.pickEvent; });
    }
  }

  String _buildCustomLevelEvent(Map<String, dynamic> game, String platform, int level) {
    final events = (game['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final lvEvent = events.firstWhere(
      (e) => (e['eventType'] ?? '').toString().toLowerCase().contains('level') ||
             (e['eventName'] ?? '').toString().contains(RegExp(r'\d')),
      orElse: () => <String, dynamic>{},
    );

    if (lvEvent.isNotEmpty) {
      final name = (lvEvent['eventName'] as String? ?? '');
      if (name.contains(RegExp(r'\d+'))) {
        return name.replaceFirst(RegExp(r'\d+'), '$level');
      }
      return '$name$level';
    }

    return platform == 'singular' ? 'sng_level_achieved_$level' : 'level_$level';
  }

  String _buildCustomLevelToken(Map<String, dynamic> game, String platform, int level) {
    if (platform != 'adj') return '';
    final events = (game['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (events.isNotEmpty) {
      return events.first['eventToken'] as String? ?? '';
    }
    return '';
  }

  String _platformLabel(String? p) {
    switch (p) {
      case 'af':       return 'AppsFlyer';
      case 'singular': return 'Singular';
      case 'adj':      return 'Adjust';
      default:         return p ?? '';
    }
  }

  Color _platformColor(String? p) {
    switch (p) {
      case 'af':       return AppTheme.primary;
      case 'singular': return AppTheme.primary;
      case 'adj':      return AppTheme.primary;
      default:         return AppTheme.primary;
    }
  }

  String _masked(String s) {
    if (s.length <= 8) return s;
    return '${s.substring(0, 8)}...';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.cardBg, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          _build3DLogo(28),
          const SizedBox(width: 10),
          const Text('محرك الأحداث', style: TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.bold,
            fontSize: 18, color: AppTheme.textPrimary,
          )),
        ]),
        actions: [
          if (_phase != _Phase.idle && _phase != _Phase.loadingApps && _phase != _Phase.detecting)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              tooltip: 'بدء من جديد',
              onPressed: _reset,
            ),
        ],
      ),
      body: Column(children: [
        if (_dailyUsage != null) _buildUsageBar(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildPhaseContent(),
            if (_log.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildTerminal(),
            ],
          ]),
        )),
      ]),
    );
  }

  // 3D Rotating VIP Logo
  Widget _build3DLogo(double size) {
    return AnimatedBuilder(
      animation: _logoCtrl,
      builder: (_, child) {
        final angle = _logoCtrl.value * 2 * 3.14159265;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF333333), Color(0xFF0A0A0A)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 12, spreadRadius: 1),
            BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.diamond_outlined, size: size * 0.5, color: AppTheme.primary),
              Padding(
                padding: EdgeInsets.only(top: size * 0.15),
                child: Text('VIP', style: TextStyle(
                  fontSize: size * 0.18, fontWeight: FontWeight.w900,
                  color: Colors.black, letterSpacing: 1,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.loadingApps:
        return _buildIdleCard();
      case _Phase.detecting:
        return _buildSpinner('اكتشاف اللعبة واستخراج المعرفات...', 'يتم فحص المنصة والجهاز في نفس الوقت');
      case _Phase.pickEvent:
        return _buildEventPicker();
      case _Phase.sending:
        return _buildSpinner('إرسال الحدث...', 'يرجى الانتظار');
      case _Phase.done:
        return _buildDoneCard();
    }
  }

  Widget _buildUsageBar() {
    final d = _dailyUsage!;
    if (d['hasSubscription'] != true) {
      return _infoBar(
        color: AppTheme.error,
        icon: Icons.warning_amber_outlined,
        text: 'لا يوجد اشتراك نشط — اشترك في باقة للمتابعة',
      );
    }
    final used      = (d['used']      as num?)?.toInt() ?? 0;
    final limit     = (d['limit']     as num?)?.toInt() ?? 1;
    final remaining = (d['remaining'] as num?)?.toInt() ?? 0;
    final progress  = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final barColor  = remaining == 0
        ? AppTheme.error
        : remaining < (limit * 0.2) ? AppTheme.warning : AppTheme.success;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.bolt, color: barColor, size: 15),
          const SizedBox(width: 6),
          Text(d['planName']?.toString() ?? 'باقتك',
              style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
          const Spacer(),
          Text('$used / $limit عملية',
              style: TextStyle(color: barColor, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }

  Widget _infoBar({required Color color, required IconData icon, required String text}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 12))),
      ]),
    );
  }

  Widget _buildIdleCard() {
    final loading = _phase == _Phase.loadingApps;
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.glassBorder, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        _build3DLogo(76),
        const SizedBox(height: 20),
        Text(
          loading ? 'جاري تحميل التطبيقات...' : 'محرك إرسال الأحداث',
          style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary, fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'يعرض التطبيقات المفتوحة حالياً،\nاختر اللعبة وسيكتشف المنصة ويرسل الحدث تلقائياً',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 13, height: 1.65),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : _startFlow,
            icon: loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.play_circle_outline, size: 20, color: Colors.black),
            label: Text(loading ? 'جاري التحميل...' : 'عرض التطبيقات المفتوحة',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.surfaceVariant,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSpinner(String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo',
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
      ]),
    );
  }

  Widget _buildEventPicker() {
    final game     = _game!;
    final platform = _platform ?? '';
    final pColor   = _platformColor(platform);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.success.withOpacity(0.35)),
        ),
        child: Row(children: [
          Text(game['emoji'] ?? '🎮', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(game['displayName'] ?? '',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary, fontSize: 15)),
            const SizedBox(height: 5),
            Wrap(spacing: 6, children: [
              _badge(_platformLabel(platform), pColor),
              _badge('تم الكشف', AppTheme.success),
            ]),
          ])),
        ]),
      ),
      const SizedBox(height: 12),

      _buildIdsSection(),
      const SizedBox(height: 12),

      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bolt, color: AppTheme.primary, size: 17),
            const SizedBox(width: 8),
            const Text('اختر الحدث',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary, fontSize: 15)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${_events.length} حدث',
                style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 12),

          ..._events.map((ev) => _buildEventTile(ev)),

          _buildCustomLevelTile(),
        ]),
      ),
      const SizedBox(height: 16),

      ElevatedButton.icon(
        onPressed: _sendEvent,
        icon: const Icon(Icons.send_rounded, size: 20, color: Colors.black),
        label: const Text('إرسال الحدث',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ]);
  }

  Widget _buildIdsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.fingerprint, color: AppTheme.primary, size: 17),
          SizedBox(width: 8),
          Text('معرفات الجهاز',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary, fontSize: 14)),
        ]),
        const SizedBox(height: 10),

        _idRow('GAID', _gaid),
        if (_showManualGaid) ...[
          const SizedBox(height: 8),
          _manualField(
            controller: _gaidCtrl,
            hint: 'أدخل GAID يدوياً (مطلوب)',
            label: 'GAID',
          ),
        ],

        if (_platform == 'af' || _platform == 'singular') ...[
          const SizedBox(height: 8),
          _idRow('AF UID', _afUid),
          if (_showManualAfUid) ...[
            const SizedBox(height: 8),
            _manualField(
              controller: _afUidCtrl,
              hint: 'أدخل AF UID يدوياً (اختياري)',
              label: 'AF UID',
            ),
          ],
        ],
      ]),
    );
  }

  Widget _idRow(String label, String value) {
    final found = value.isNotEmpty;
    return Row(children: [
      Icon(found ? Icons.check_circle_outline : Icons.error_outline,
          color: found ? AppTheme.success : AppTheme.warning, size: 15),
      const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
      Expanded(child: Text(
        found ? _masked(value) : 'لم يتم الحصول عليه',
        style: TextStyle(
          color: found ? AppTheme.textPrimary : AppTheme.warning,
          fontFamily: 'monospace', fontSize: 11,
          fontWeight: found ? FontWeight.bold : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      )),
    ]);
  }

  Widget _manualField({required TextEditingController controller, required String hint, required String label}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 12, fontFamily: 'Cairo'),
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Cairo'),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildEventTile(Map<String, dynamic> ev) {
    final selected = !_customLevel && _selectedEvent?['eventName'] == ev['eventName'];
    return GestureDetector(
      onTap: () => setState(() { _selectedEvent = ev; _customLevel = false; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.14) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.primary : AppTheme.textHint, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ev['displayName'] ?? ev['eventName'] ?? '',
                style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 13,
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                )),
            Text(ev['eventName'] ?? '',
                style: const TextStyle(color: AppTheme.textHint, fontSize: 10, fontFamily: 'monospace')),
          ])),
        ]),
      ),
    );
  }

  Widget _buildCustomLevelTile() {
    return GestureDetector(
      onTap: () => setState(() { _customLevel = true; _selectedEvent = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _customLevel ? AppTheme.primary.withOpacity(0.12) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _customLevel ? AppTheme.primary : AppTheme.border,
            width: _customLevel ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_customLevel ? Icons.radio_button_checked : Icons.radio_button_off,
                color: _customLevel ? AppTheme.primary : AppTheme.textHint, size: 18),
            const SizedBox(width: 10),
            const Text('لفل مخصص',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                    color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            const Text('أدخل رقم اللفل',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textHint)),
          ]),
          if (_customLevel) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customLevelCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo',
                  fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'مثال: 5',
                hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 16),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                suffixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Level', style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _customLevelCtrl,
              builder: (_, val, __) {
                final lvl = int.tryParse(val.text.trim().isEmpty ? '0' : val.text.trim()) ?? 0;
                if (lvl <= 0) return const SizedBox.shrink();
                final preview = _buildCustomLevelEvent(_game!, _platform ?? '', lvl);
                return Text('سيُرسل: $preview',
                    style: const TextStyle(color: AppTheme.textHint, fontSize: 11, fontFamily: 'monospace'));
              },
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildDoneCard() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (_resultOk ? AppTheme.success : AppTheme.error).withOpacity(0.4),
          ),
        ),
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_resultOk ? AppTheme.success : AppTheme.error).withOpacity(0.12),
            ),
            child: Icon(
              _resultOk ? Icons.check_circle_outline : Icons.error_outline,
              color: _resultOk ? AppTheme.success : AppTheme.error, size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(_resultMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Cairo',
                color: _resultOk ? AppTheme.success : AppTheme.error,
              )),
          if (_resultHttp != null) ...[
            const SizedBox(height: 6),
            Text('HTTP $_resultHttp',
                style: const TextStyle(color: AppTheme.textHint, fontFamily: 'monospace', fontSize: 12)),
          ],
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() { _phase = _Phase.pickEvent; }),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إرسال مجدداً', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('لعبة جديدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.black)),
            )),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildTerminal() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.error.withOpacity(0.7))),
            const SizedBox(width: 6),
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.warning.withOpacity(0.7))),
            const SizedBox(width: 6),
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.success.withOpacity(0.7))),
            const SizedBox(width: 10),
            const Text('سجل العمليات', style: TextStyle(color: AppTheme.textHint, fontSize: 11, fontFamily: 'monospace')),
          ]),
          const SizedBox(height: 10),
          ..._log.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: const TextStyle(
              color: Color(0xFF7FD9A0), fontFamily: 'monospace', fontSize: 11, height: 1.45,
            )),
          )),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
    );
  }
}

class _AppPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> apps;
  const _AppPickerSheet({required this.apps});
  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.apps
        : widget.apps.where((a) {
            final name = (a['name'] ?? a['label'] ?? '').toString().toLowerCase();
            final pkg  = (a['package'] ?? '').toString().toLowerCase();
            final q    = _query.toLowerCase();
            return name.contains(q) || pkg.contains(q);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65, maxChildSize: 0.95, minChildSize: 0.45, expand: false,
      builder: (_, scroll) => Column(children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        const Text('اختر التطبيق المفتوح',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary, fontFamily: 'Cairo')),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'بحث...',
              hintStyle: const TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo'),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint, size: 18),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: AppTheme.border, height: 16),

        Expanded(child: filtered.isEmpty
          ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo')))
          : ListView.builder(
              controller: scroll,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final app = filtered[i];
                final name = app['name'] ?? app['label'] ?? app['package'] ?? '';
                return ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gamepad_outlined, color: AppTheme.primary, size: 22),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(app['package'] ?? '',
                      style: const TextStyle(color: AppTheme.textHint, fontSize: 10, fontFamily: 'monospace')),
                  onTap: () => Navigator.pop(context, app),
                );
              },
            ),
        ),
      ]),
    );
  }
}
