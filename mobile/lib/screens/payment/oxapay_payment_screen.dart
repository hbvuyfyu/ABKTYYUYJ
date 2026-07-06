import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// USDT payment via OxaPay - opens a WebView with the OxaPay checkout page.
/// Polls the backend every 5 seconds for payment confirmation.
/// Automatically activates the subscription once OxaPay confirms payment.
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
  String? _payAmountDisplay;
  String? _trackId;
  WebViewController? _webController;
  Timer? _pollTimer;
  bool _isPaid = false;
  int _pollCount = 0;
  bool _webViewReady = false;

  static const int _maxPollCount = 120; // 10 minutes (5s interval)

  @override
  void initState() {
    super.initState();
    _createOxapayPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createOxapayPayment() async {
    try {
      final res = await ApiService.post(
        '/payments/${widget.paymentId}/oxapay/create',
        {},
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};

        final paymentUrl = data['paymentUrl']?.toString();
        final trackId = data['trackId']?.toString();

        // Build display amount string
        final payAmount = data['payAmount'] ?? data['amount'];
        final payCurrency = data['payCurrency']?.toString() ?? 'USDT';
        final amountDisplay = payAmount != null
            ? '${double.tryParse(payAmount.toString())?.toStringAsFixed(2) ?? payAmount} $payCurrency'
            : null;

        if (paymentUrl == null) {
          setState(() {
            _error = 'لم يتم إنشاء رابط الدفع';
            _loading = false;
          });
          return;
        }

        _paymentUrl = paymentUrl;
        _trackId = trackId;
        _payAmountDisplay = amountDisplay;

        // Build WebView controller
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                // OxaPay redirects to return_url after payment — catch it
                if (url.contains('payment-callback') ||
                    url.contains('paymentId=${widget.paymentId}') ||
                    url.contains('oxapay-return')) {
                  _checkPaymentStatus();
                }
              },
              onPageFinished: (_) {
                if (!_webViewReady && mounted) {
                  setState(() => _webViewReady = true);
                }
              },
              onWebResourceError: (err) {
                debugPrint('[OxaPay WebView] resource error: ${err.description}');
              },
            ),
          )
          ..loadRequest(Uri.parse(paymentUrl));

        setState(() {
          _webController = controller;
          _loading = false;
        });

        _startPolling();
      } else {
        setState(() {
          _error = res['message']?.toString() ?? 'فشل إنشاء رابط الدفع';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'خطأ في الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      _pollCount++;
      if (_pollCount > _maxPollCount) {
        _pollTimer?.cancel();
        return;
      }
      await _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final res = await ApiService.get(
        '/payments/${widget.paymentId}/oxapay/status',
      );
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final approved = data['approved'] == true ||
            data['status'] == 'APPROVED' ||
            data['paid'] == true;

        if (approved && mounted && !_isPaid) {
          _pollTimer?.cancel();
          setState(() => _isPaid = true);
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
          ? const _LoadingWidget()
          : _isPaid
              ? _buildSuccessView()
              : _error != null
                  ? _buildErrorView()
                  : _buildWebViewBody(),
    );
  }

  Widget _buildSuccessView() {
    // Auto-navigate after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/');
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.success, size: 72),
            ),
            const SizedBox(height: 24),
            const Text(
              'تم الدفع بنجاح!',
              style: TextStyle(
                color: AppTheme.success,
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'تم تفعيل اشتراكك تلقائياً',
              style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 14),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'جارٍ التحويل...',
              style: TextStyle(color: AppTheme.textHint, fontFamily: 'Cairo', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                      _pollCount = 0;
                    });
                    _createOxapayPayment();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewBody() {
    return Column(
      children: [
        // Payment info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.currency_bitcoin, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_payAmountDisplay != null)
                      Text(
                        'المبلغ: $_payAmountDisplay',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    const Text(
                      'سيتم تفعيل اشتراكك تلقائياً بعد الدفع',
                      style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo', fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Polling indicator
              const SizedBox(
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
          child: Stack(
            children: [
              if (_webController != null)
                WebViewWidget(controller: _webController!),

              // Show loader until first page is loaded
              if (!_webViewReady)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 16),
          Text(
            'جارٍ إعداد بوابة الدفع...',
            style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
}
