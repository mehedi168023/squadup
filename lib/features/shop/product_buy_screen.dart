import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/validators.dart';
import '../../app/core/app_toast.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/models/misc_models.dart';
import '../../app/data/services/bd_location_api.dart';
import '../../app/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
import '../../app/widgets/premium_back_button.dart';
import '../../app/widgets/primary_button.dart';
import '../../app/widgets/responsive.dart';
import '../../app/widgets/skeleton.dart';

/// Premium gaming-store checkout: pick quantity + colour, choose a delivery
/// division, enter the full address and phone, then place the order. The price
/// total (items × qty + courier charge) updates live and rides in a sticky
/// bottom bar.
class ProductBuyScreen extends StatefulWidget {
  const ProductBuyScreen({super.key});

  @override
  State<ProductBuyScreen> createState() => _ProductBuyScreenState();
}

class _ProductBuyScreenState extends State<ProductBuyScreen> {
  final Product product = Get.arguments as Product;
  late String _color = product.colors.first;
  int _qty = 1;

  // Division/district loaded live from the free BD geo API.
  List<BdDivision> _divisions = [];
  BdDivision? _division;
  List<BdDistrict> _districts = [];
  BdDistrict? _district;
  bool _loadingDiv = true;
  bool _loadingDist = false;
  bool _divError = false;

  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _placing = false;
  int _paymentMethodIndex = 2; // Default to Cash on Delivery (index 2)

  double get _subtotal => product.price * _qty;
  double get _delivery => _division == null
      ? 0
      : (_division!.name == 'Dhaka'
          ? MockData.deliveryInsideDhaka
          : MockData.deliveryOutsideDhaka);
  double get _total => _subtotal + _delivery;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadDivisions() async {
    setState(() {
      _loadingDiv = true;
      _divError = false;
    });
    try {
      final list = await BdLocationApi.divisions();
      if (!mounted) return;
      setState(() {
        _divisions = list;
        _loadingDiv = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDiv = false;
        _divError = true;
      });
      AppToast.error('Could not load divisions — tap retry');
    }
  }

  Future<void> _loadDistricts(String divisionId) async {
    setState(() {
      _loadingDist = true;
      _districts = [];
      _district = null;
    });
    try {
      final list = await BdLocationApi.districts(divisionId);
      if (!mounted) return;
      setState(() {
        _districts = list;
        _loadingDist = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDist = false);
      AppToast.error('Could not load districts');
    }
  }

  Future<void> _placeOrder() async {
    if (_division == null) {
      AppToast.warning('Select your delivery division');
      return;
    }
    if (_district == null) {
      AppToast.warning('Select your district');
      return;
    }
    if (_address.text.trim().length < 6) {
      AppToast.warning('Enter your full delivery address');
      return;
    }
    final phone = _phone.text.trim();
    final phoneErr = Validators.phone(phone);
    if (phoneErr != null) {
      AppToast.error(phoneErr);
      return;
    }

    if (_paymentMethodIndex == 0) {
      // Winning Wallet payment: check winning balance
      final winningBal = SessionService.to.wallet.value.winningBalance;
      if (winningBal < _total) {
        AppToast.warning('ইনসাফিসিয়েন্ট উইনিং ব্যালেন্স (মিনিমাম ৳${_total.toStringAsFixed(2)} লাগবে)');
        return;
      }
      
      setState(() => _placing = true);
      final ok = await SessionService.to.submitProductOrder({
        'productName': product.name,
        'qty': _qty,
        'color': _color,
        'unitPrice': product.price,
        'subtotal': _subtotal,
        'deliveryCharge': _delivery,
        'total': _total,
        'divisionId': _division!.id,
        'divisionName': _division!.name,
        'districtId': _district!.id,
        'districtName': _district!.name,
        'address': _address.text.trim(),
        'phone': phone,
        'paymentMethod': 'wallet',
      });
      if (!mounted) return;
      setState(() => _placing = false);
      if (!ok) return;
      Get.back();
      AppToast.success('Order placed successfully using Winning Wallet!');
    } else if (_paymentMethodIndex == 1) {
      // Direct Gateway
      Get.toNamed(
        AppRoutes.depositWebview,
        arguments: {
          'amount': _total,
          'closeDouble': false,
          'isOrderPayment': true,
        },
      )?.then((completed) async {
        if (completed == true) {
          setState(() => _placing = true);
          final ok = await SessionService.to.submitProductOrder({
            'productName': product.name,
            'qty': _qty,
            'color': _color,
            'unitPrice': product.price,
            'subtotal': _subtotal,
            'deliveryCharge': _delivery,
            'total': _total,
            'divisionId': _division!.id,
            'divisionName': _division!.name,
            'districtId': _district!.id,
            'districtName': _district!.name,
            'address': _address.text.trim(),
            'phone': phone,
            'paymentMethod': 'gateway',
          });
          if (!mounted) return;
          setState(() => _placing = false);
          if (ok) {
            Get.back();
            AppToast.success('Order placed successfully via Online Payment!');
          }
        }
      });
    } else {
      setState(() => _placing = true);
      final ok = await SessionService.to.submitProductOrder({
        'productName': product.name,
        'qty': _qty,
        'color': _color,
        'unitPrice': product.price,
        'subtotal': _subtotal,
        'deliveryCharge': _delivery,
        'total': _total,
        'divisionId': _division!.id,
        'divisionName': _division!.name,
        'districtId': _district!.id,
        'districtName': _district!.name,
        'address': _address.text.trim(),
        'phone': phone,
        'paymentMethod': 'cod',
      });
      if (!mounted) return;
      setState(() => _placing = false);
      if (!ok) return;
      Get.back();
      AppToast.success('Order placed successfully! Please prepare cash on delivery.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const PremiumBackButton(),
        title: const Text('Checkout', style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar:
          _BottomBar(total: _total, loading: _placing, onPlace: _placeOrder),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ProductSummary(product: product),
            const SizedBox(height: 16),
            _QuantityRow(
              qty: _qty,
              onMinus: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
              onPlus: () => setState(() => _qty = (_qty + 1).clamp(1, 99)),
            ),
            if (product.colors.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ColorPicker(
                colors: product.colors,
                selected: _color,
                onSelect: (c) => setState(() => _color = c),
              ),
            ],
            const SizedBox(height: 16),
            
            // Location Selection Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _premiumCardDeco(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Delivery Location', 
                        style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DivisionDropdown(
                    divisions: _divisions,
                    value: _division,
                    loading: _loadingDiv,
                    error: _divError,
                    onRetry: _loadDivisions,
                    onChanged: (d) {
                      setState(() => _division = d);
                      if (d != null) _loadDistricts(d.id);
                    },
                  ),
                  const SizedBox(height: 12),
                  _DistrictDropdown(
                    key: ValueKey('dist-${_division?.id}'),
                    districts: _districts,
                    value: _district,
                    loading: _loadingDist,
                    enabled: _division != null,
                    onChanged: (d) => setState(() => _district = d),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _premiumCardDeco(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin_circle_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Shipping Details', 
                        style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Field(
                    controller: _address,
                    hint: 'House / road / area, city, post code…',
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _phone,
                    hint: '01XXXXXXXXX',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment Method Selection Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _premiumCardDeco(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Payment Method', 
                        style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: List.generate(3, (index) {
                      final methods = [
                        ('Winning Wallet', 'Winning Balance: ৳${SessionService.to.wallet.value.winningBalance.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined),
                        ('Online Payment', 'bKash / Nagad / Rocket / Cards', Icons.payment_outlined),
                        ('Cash on Delivery', 'Pay upon receiving product', Icons.local_shipping_outlined),
                      ];
                      final m = methods[index];
                      final isSel = _paymentMethodIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _paymentMethodIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? AppColors.primary : context.cBorder.withValues(alpha: 0.6),
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(m.$3, color: isSel ? AppColors.primary : context.cTextDim, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.$1, style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? AppColors.primary : null,
                                    )),
                                    const SizedBox(height: 2),
                                    Text(m.$2, style: AppTextStyles.body2.copyWith(
                                      color: isSel ? AppColors.primary.withValues(alpha: 0.8) : context.cTextMuted,
                                      fontSize: 12,
                                    )),
                                  ],
                                ),
                              ),
                              if (isSel)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.cBorder, width: 1.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OrderSummary(
              qty: _qty,
              subtotal: _subtotal,
              delivery: _delivery,
              total: _total,
            ),
            const SizedBox(height: 16),
            
            // Shipping Notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cash on Delivery · ${taka(MockData.deliveryInsideDhaka)} inside Dhaka, '
                      '${taka(MockData.deliveryOutsideDhaka)} outside Dhaka.',
                      style:
                          AppTextStyles.body2.copyWith(color: context.cTextDim, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Building blocks ───────────────────────────────────────────────────────

BoxDecoration _premiumCardDeco(BuildContext context) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.cSurface,
          context.cSurface.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.cBorder.withValues(alpha: 0.8)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

/// Maps a colour name to a display swatch.
Color _swatch(String name) {
  switch (name.toLowerCase()) {
    case 'black':
      return const Color(0xFF2A2A2A);
    case 'white':
      return const Color(0xFFE6E8EC);
    case 'red':
      return AppColors.danger;
    case 'blue':
      return AppColors.primary;
    case 'green':
      return AppColors.matchesGreen;
    case 'gold':
      return AppColors.gold;
    default:
      return AppColors.primary;
  }
}

class _ProductSummary extends StatelessWidget {
  final Product product;
  const _ProductSummary({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasOld =
        product.oldPrice != null && product.oldPrice! > product.price;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDeco(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 96,
                height: 96,
                color: AppColors.primary.withValues(alpha: 0.05),
                child: product.image != null
                    ? Image.asset(product.image!,
                        fit: BoxFit.cover,
                        cacheWidth: 260,
                        errorBuilder: (_, __, ___) => Icon(product.icon,
                            size: 40, color: AppColors.primary))
                    : Icon(product.icon, size: 40, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(taka(product.price),
                        style: AppTextStyles.h2.copyWith(
                            fontSize: 21, color: AppColors.matchesGreen, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (hasOld)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(taka(product.oldPrice!),
                            style: AppTextStyles.body2.copyWith(
                              color: context.cTextMuted,
                              decoration: TextDecoration.lineThrough,
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    StatusPill(
                      text: 'In Stock',
                      color: AppColors.matchesGreen,
                    ),
                    SizedBox(width: 8),
                    StatusPill(
                      text: 'Premium Delivery',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityRow extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _QuantityRow(
      {required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _premiumCardDeco(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantity',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600, color: context.cTextDim),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.cBgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cBorder),
            ),
            child: Row(
              children: [
                _StepBtn(icon: Icons.remove_rounded, onTap: onMinus),
                SizedBox(
                  width: 50,
                  child: Text('$qty',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _StepBtn(icon: Icons.add_rounded, onTap: onPlus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B7BF0), Color(0xFF16357D)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onSelect;
  const _ColorPicker(
      {required this.colors, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Color',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600, color: context.cTextDim),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((c) {
              final sel = c == selected;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(c);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          )
                        : null,
                    color: sel ? null : context.cBgAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? AppColors.primary : context.cBorder,
                      width: sel ? 1.5 : 1,
                    ),
                    boxShadow: sel ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _swatch(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(c,
                          style: AppTextStyles.title.copyWith(
                              fontSize: 14,
                              fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                              color: sel ? context.cText : context.cTextDim)),
                      if (sel) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DivisionDropdown extends StatelessWidget {
  final List<BdDivision> divisions;
  final BdDivision? value;
  final bool loading;
  final bool error;
  final VoidCallback onRetry;
  final ValueChanged<BdDivision?> onChanged;
  const _DivisionDropdown({
    required this.divisions,
    required this.value,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CrossFade(
      showFirst: error,
      first: _RetryRow(label: 'Failed to load divisions', onRetry: onRetry),
      second: DropdownButtonFormField<BdDivision>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: context.cSurface,
        borderRadius: BorderRadius.circular(12),
        icon: loading
            ? const _MiniSpinner()
            : const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
        style: AppTextStyles.body1.copyWith(color: context.cText, fontSize: 15),
        decoration: InputDecoration(
          hintText: loading ? 'Loading divisions…' : 'Select division',
          hintStyle: AppTextStyles.body2.copyWith(color: context.cTextMuted),
          prefixIcon: const Icon(Icons.map_outlined, color: AppColors.primary),
          fillColor: context.cBgAlt,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.cBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.cBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        items: divisions
            .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text('${d.name}  •  ${d.bnName}',
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (loading || divisions.isEmpty) ? null : onChanged,
      ),
    );
  }
}

class _DistrictDropdown extends StatelessWidget {
  final List<BdDistrict> districts;
  final BdDistrict? value;
  final bool loading;
  final bool enabled;
  final ValueChanged<BdDistrict?> onChanged;
  const _DistrictDropdown({
    super.key,
    required this.districts,
    required this.value,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hint = !enabled
        ? 'Select a division first'
        : (loading ? 'Loading districts…' : 'Select district');
    return DropdownButtonFormField<BdDistrict>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: context.cSurface,
      borderRadius: BorderRadius.circular(12),
      icon: loading
          ? const _MiniSpinner()
          : const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
      style: AppTextStyles.body1.copyWith(color: context.cText, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body2.copyWith(color: context.cTextMuted),
        prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primary),
        fillColor: context.cBgAlt,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.cBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.cBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: districts
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text('${d.name}  •  ${d.bnName}',
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (!enabled || loading || districts.isEmpty) ? null : onChanged,
    );
  }
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 18,
        height: 18,
        child:
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
}

class _RetryRow extends StatelessWidget {
  final String label;
  final VoidCallback onRetry;
  const _RetryRow({required this.label, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 18, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: AppTextStyles.body1.copyWith(color: context.cText))),
            const Icon(Icons.refresh_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('Retry',
                style: AppTextStyles.title
                    .copyWith(color: AppColors.primary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.body1.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body2.copyWith(color: context.cTextMuted),
        fillColor: context.cBgAlt,
        filled: true,
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 44 : 0),
          child: Icon(icon, color: AppColors.primary.withValues(alpha: 0.7)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.cBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.cBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final int qty;
  final double subtotal;
  final double delivery;
  final double total;
  const _OrderSummary({
    required this.qty,
    required this.subtotal,
    required this.delivery,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Order Summary', 
                style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _row(context, 'Subtotal ($qty item${qty > 1 ? 's' : ''})',
              taka(subtotal)),
          const SizedBox(height: 10),
          _row(context, 'Delivery charge',
              delivery == 0 ? 'Select division' : taka(delivery),
              dim: delivery == 0),
          const SizedBox(height: 12),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.cBorder.withValues(alpha: 0.1),
                  context.cBorder,
                  context.cBorder.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _row(context, 'Total', taka(total), emphasize: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool emphasize = false, bool dim = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: emphasize
                ? AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.bold)
                : AppTextStyles.body1.copyWith(color: context.cTextDim)),
        Text(value,
            style: emphasize
                ? AppTextStyles.h2
                    .copyWith(fontSize: 18, color: AppColors.matchesGreen, fontWeight: FontWeight.bold)
                : AppTextStyles.title.copyWith(
                    fontSize: 14,
                    color: dim ? context.cTextMuted : context.cText)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double total;
  final bool loading;
  final VoidCallback onPlace;
  const _BottomBar(
      {required this.total, required this.loading, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cSurface.withValues(alpha: 0.85),
        border: Border(top: BorderSide(color: context.cBorder.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ]
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Payable',
                          style: AppTextStyles.body2
                              .copyWith(color: context.cTextDim, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(taka(total),
                          style: AppTextStyles.h2.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.matchesGreen)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Place Order',
                      icon: Icons.shopping_bag_rounded,
                      variant: ButtonVariant.green,
                      loading: loading,
                      onPressed: onPlace,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
