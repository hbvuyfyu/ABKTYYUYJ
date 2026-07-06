import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class OxapayPaymentScreen extends StatefulWidget {
  final String paymentId;
  const OxapayPaymentScreen({super.key, required this.paymentId});

  @override
  State<OxapayPaymentScreen> createState() => _OxapayPaymentScreenState();
}

class _OxapayPaymentScreenState extends State<OxapayPaymentScreen> {
  bool _loading = true;
  String? _paymentUrl;
  String? _error;
  double? _amount;
  String? _trackId;
  late WebViewController _webViewController;
  Timer? _pollTimer;
  bool _isPaid = false;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    _createPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createPayment() async {
    try {
      final res = await ApiService.post('/payments/${widget.paymentId}/oxapay/create', {});
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        setState(() {
          _paymentUrl = data['paymentUrl'] as String?;
          _amount = (data['payAmount'] ?? data['amount']) as double?;
          _trackId = data['trackId'] as String?;
          _loading = false;
        });

        // Initialize WebView
        if (_paymentUrl != null) {
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) {
                  // Check if payment was completed (return URL)
                  if (url.contains('payment-callback') || url.contains('paymentId=${widget.paymentId}')) {
                    _checkPaymentStatus();
                  }
                },
              ),
            )
            ..loadRequest(Uri.parse(_paymentUrl!));

          // Start polling for payment status
          _startPolling();
        }
      } else {
        setState(() {
          _error = res['message']?.toString() ?? 'فشل إنشاء رابط الدفع';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollCount++;
      if (_pollCount > 60) { // Stop after 5 minutes
        timer.cancel();
        return;
      }
      await _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final res = await ApiService.get('/payments/${widget.paymentId}/oxapay/status');
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        if (data['approved'] == true || data['status'] == 'APPROVED') {
          _pollTimer?.cancel();
          setState(() => _isPaid = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم تأكيد الدفع وتفعيل الاشتراك!', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 3),
            ));
            // Navigate to home after delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) context.go('/');
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفع USDT عبر OxaPay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            _pollTimer?.cancel();
            context.pop();
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ),
                )
              : _isPaid
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: AppTheme.success, size: 64),
                          ),
                          const SizedBox(height: 24),
                          const Text('تم الدفع بنجاح!', style: TextStyle(color: AppTheme.success, fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('جارٍ تفعيل الاشتراك...', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo')),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Header info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            border: Border(bottom: BorderSide(color: AppTheme.border)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.currency_bitcoin, color: AppTheme.accent, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('المبلغ: ${_amount?.toStringAsFixed(2) ?? ''} USDT', style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                    const Text('انتظر تأكيد الدفع تلقائياً', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 12)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // WebView
                        Expanded(
                          child: WebViewWidget(controller: _webViewController),
                        ),
                      ],
                    ),
    );
  }
}
