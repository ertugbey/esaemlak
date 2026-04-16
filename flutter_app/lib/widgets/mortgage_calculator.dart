import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Mortgage/Loan calculator widget for property listings
/// Calculates monthly payment based on price, down payment, interest rate, and term
class MortgageCalculatorWidget extends StatefulWidget {
  final double propertyPrice;
  final String? propertyTitle;

  const MortgageCalculatorWidget({
    super.key,
    required this.propertyPrice,
    this.propertyTitle,
  });

  @override
  State<MortgageCalculatorWidget> createState() => _MortgageCalculatorWidgetState();
}

class _MortgageCalculatorWidgetState extends State<MortgageCalculatorWidget> {
  late double _loanAmount;
  double _downPaymentPercent = 20.0;
  double _interestRate = 2.5; // Monthly rate (Turkish banks)
  int _termYears = 10;
  
  double get _downPayment => widget.propertyPrice * (_downPaymentPercent / 100);
  double get _actualLoanAmount => widget.propertyPrice - _downPayment;
  
  @override
  void initState() {
    super.initState();
    _loanAmount = widget.propertyPrice * 0.8; // Default 80% loan
  }

  /// Calculate monthly payment using standard mortgage formula
  double _calculateMonthlyPayment() {
    if (_actualLoanAmount <= 0) return 0;
    
    final monthlyRate = _interestRate / 100;
    final totalMonths = _termYears * 12;
    
    if (monthlyRate == 0) {
      return _actualLoanAmount / totalMonths;
    }
    
    // Standard mortgage formula: M = P * [r(1+r)^n] / [(1+r)^n - 1]
    final pow = _pow(1 + monthlyRate, totalMonths);
    final payment = _actualLoanAmount * (monthlyRate * pow) / (pow - 1);
    
    return payment;
  }

  double _pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  double _calculateTotalPayment() {
    return _calculateMonthlyPayment() * _termYears * 12;
  }

  double _calculateTotalInterest() {
    return _calculateTotalPayment() - _actualLoanAmount;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)} M TL';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} K TL';
    }
    return '${amount.toStringAsFixed(0)} TL';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyPayment = _calculateMonthlyPayment();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkCard, AppTheme.darkBackground]
              : [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.blue.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calculate, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kredi Hesaplama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Aylık taksit tutarınızı hesaplayın',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Property price display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Emlak Fiyatı'),
                Text(
                  _formatCurrency(widget.propertyPrice),
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Down payment slider
          _buildSlider(
            label: 'Peşinat',
            value: _downPaymentPercent,
            min: 0,
            max: 90,
            suffix: '%',
            displayValue: '${_downPaymentPercent.toInt()}% (${_formatCurrency(_downPayment)})',
            onChanged: (v) => setState(() => _downPaymentPercent = v),
          ),
          const SizedBox(height: 12),
          
          // Interest rate slider
          _buildSlider(
            label: 'Aylık Faiz Oranı',
            value: _interestRate,
            min: 0.5,
            max: 5.0,
            suffix: '%',
            displayValue: '${_interestRate.toStringAsFixed(2)}%',
            onChanged: (v) => setState(() => _interestRate = v),
            divisions: 90,
          ),
          const SizedBox(height: 12),
          
          // Term slider
          _buildSlider(
            label: 'Vade',
            value: _termYears.toDouble(),
            min: 1,
            max: 20,
            suffix: ' yıl',
            displayValue: '$_termYears yıl (${_termYears * 12} ay)',
            onChanged: (v) => setState(() => _termYears = v.toInt()),
            divisions: 19,
          ),
          
          const Divider(height: 32),
          
          // Results
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  label: 'Kredi Tutarı',
                  value: _formatCurrency(_actualLoanAmount),
                  icon: Icons.account_balance,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  label: 'Toplam Faiz',
                  value: _formatCurrency(_calculateTotalInterest()),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Monthly payment highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Aylık Taksit',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(monthlyPayment),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam: ${_formatCurrency(_calculateTotalPayment())}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Disclaimer
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu hesaplama tahmini olup, gerçek kredi koşulları bankalara göre değişiklik gösterebilir.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required String displayValue,
    required Function(double) onChanged,
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(displayValue, style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryBlue,
            inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.2),
            thumbColor: AppTheme.primaryBlue,
            overlayColor: AppTheme.primaryBlue.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to show mortgage calculator
void showMortgageCalculator(BuildContext context, double propertyPrice, String? propertyTitle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: MortgageCalculatorWidget(
                  propertyPrice: propertyPrice,
                  propertyTitle: propertyTitle,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
