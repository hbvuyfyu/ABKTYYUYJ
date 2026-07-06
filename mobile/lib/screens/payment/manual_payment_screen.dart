import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

/// Manual payment screen for ShamCash and Syriatel Cash
/// - Shows copyable payment address
/// - Accepts transaction number OR image proof
/// - Submits to admin for approval
class ManualPaymentScreen extends StatefulWidget {
  final String paymentId;
  const ManualPaymentScreen({super.key, required this.paymentId});

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  Map<String, dynamic>? _payment;
  Map<String, dynamic>? _settings;
  bool _loading = true;

  final _txNoController = TextEditingController();
  XFile? _pickedImage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _txNoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.get('/users/payment-history'),
        ApiService.get('/settings/payment', auth: false),
      ]);

      if (results[0]['success'] == true) {
        final payments = (results[0]['data'] as List?) ?? [];
        for (final p in payments) {
          if ((p as Map)['id'] == widget.paymentId) {
            _payment = p as Map<String, dynamic>;
            break;
          }
        }
        if (_payment == null) {
          _payment = {
            'id': widget.paymentId,
            'method': 'SHAM_CASH',
            'amount': 0,
          };
        }
      }

      if (results[1]['success'] == true) {
        _settings = results[1]['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      _payment = {
        'id': widget.paymentId,
        'method': 'SHAM_CASH',
        'amount': 0,
      };
    }

    setState(() => _loading = false);
  }

  bool get _isShamCash {
    final method = _payment?['method'] as String?;
    return method == 'SHAM_CASH';
  }

  String get _paymentAddress {
    if (_isShamCash) {
      return _settings?['sham_cash_account_address'] ??
             _settings?['sham_cash_number'] ??
             'لم يتم تكوين العنوان';
    } else {
      return _settings?['syriatel_cash_number'] ??
             _settings?['syriatel_cash_gsm'] ??
             'لم يتم تكوين الرقم';
    }
  }

  double get _amountUsd {
    final amount = _payment?['amount'];
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    return 0.0;
  }

  int get _amountSp {
    final rate = double.tryParse(_settings?['syria_usd_to_sp_rate'] ?? '15000') ?? 15000;
    return (_amountUsd * rate).round();
  }

  void _copyAddress() {
    Clipboard.setData(ClipboardData(text: _paymentAddress));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم نسخ العنوان', style: TextStyle(fontFamily: 'Cairo')),
      backgroundColor: AppTheme.success,
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  Future<void> _submitProof() async {
    final txNo = _txNoController.text.trim();
    final hasImage = _pickedImage != null;

    if (txNo.isEmpty && !hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل رقم العملية أو أرفق صورة الإثبات', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.warning,
        duration: Duration(seconds: 2),
      ));
      return;
    }

    setState(() => _submitting = true);

    try {
      // Prepare request body
      Map<String, dynamic> body = {};

      if (txNo.isNotEmpty) {
        body['transactionNo'] = txNo;
      }

      if (hasImage) {
        final bytes = await File(_pickedImage!.path).readAsBytes();
        body['imageBase64'] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // Submit proof for admin approval
      final res = await ApiService.post(
        '/payments/${widget.paymentId}/submit-proof',
        body,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            res['message']?.toString() ?? 'فشل إرسال الإثبات',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('خطأ في الاتصال، حاول مرة أخرى', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.error,
        duration: Duration(seconds: 3),
      ));
    }

    setState(() => _submitting = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم إرسال طلبك بنجاح',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم مراجعة طلبك من قبل الإدارة وتفعيل اشتراكك خلال دقائق',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('العودة للرئيسية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isShamCash ? 'دفع عبر ShamCash' : 'دفع عبر Syriatel Cash'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment info card
                  _buildPaymentInfoCard(),

                  const SizedBox(height: 24),

                  // Instructions
                  _buildInstructions(),

                  const SizedBox(height: 24),

                  // Transaction number input
                  const Text(
                    'رقم العملية (اختياري):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _txNoController,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'رقم العملية',
                      hintText: 'أدخل رقم العملية من التطبيق',
                      prefixIcon: const Icon(Icons.tag, color: AppTheme.primary),
                      suffixIcon: _txNoController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.textHint),
                              onPressed: () => setState(() => _txNoController.clear()),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  // Image upload
                  const Text(
                    'أو أرفق صورة إثبات الدفع (اختياري):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildImagePicker(),

                  const SizedBox(height: 32),

                  // Submit button
                  GradientButton(
                    onPressed: _submitting ? null : _submitProof,
                    isLoading: _submitting,
                    text: 'إرسال للمراجعة',
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Center(
                    child: Text(
                      'سيتم تفعيل اشتراكك بعد موافقة الإدارة',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isShamCash ? Icons.account_balance_wallet_outlined : Icons.phone_android_outlined,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isShamCash ? 'ShamCash' : 'Syriatel Cash',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Payment address/number
          Text(
            _isShamCash ? 'عنوان الاستلام:' : 'رقم الاستلام:',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontFamily: 'Cairo',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _paymentAddress,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'Courier',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppTheme.primary, size: 22),
                  onPressed: _copyAddress,
                  tooltip: 'نسخ',
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.border, height: 32),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المبلغ المطلوب:',
                    style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_amountUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              if (!_isShamCash)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'بالليرة السورية:',
                      style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_amountSp S.P',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
              const SizedBox(width: 8),
              const Text(
                'خطوات الدفع:',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. انسخ ${_isShamCash ? "العنوان" : "الرقم"} أعلاه\n'
            '2. افتح تطبيق ${_isShamCash ? "ShamCash" : "Syriatel Cash"}\n'
            '3. قم بتحويل المبلغ المطلوب\n'
            '4. بعد التحويل، أخذ لقطة شاشة أو انسخ رقم العملية\n'
            '5. أدخل رقم العملية أو ارفق الصورة أدناه\n'
            '6. اضغط "إرسال للمراجعة"',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontFamily: 'Cairo',
              fontSize: 13,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pickedImage != null ? AppTheme.success : AppTheme.border,
            width: _pickedImage != null ? 2 : 1,
          ),
        ),
        child: _pickedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      File(_pickedImage!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'اضغط لاختيار صورة',
                    style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Cairo'),
                  ),
                ],
              ),
      ),
    );
  }
}
