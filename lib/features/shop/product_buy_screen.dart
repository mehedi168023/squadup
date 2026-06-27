import 'package:flutter/material.dart';
import '../../app/widgets/premium_back_button.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/core/app_constants.dart';
import '../../app/core/validators.dart';
import '../../app/core/app_toast.dart';
import '../../app/data/mock/mock_data.dart';
import '../../app/data/models/misc_models.dart';
import '../../app/data/services/bd_location_api.dart';
import '../../app/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/widgets/common_widgets.dart';
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
    final orderId = SessionService.to.orders.first.id;
    Get.back();
    AppToast.success(
        'Order #$orderId placed! $_qty× ${product.name} • ${taka(_total)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const PremiumBackButton(), title: const Text('Checkout')),
      bottomNavigationBar:
          _BottomBar(total: _total, loading: _placing, onPlace: _placeOrder),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _ProductSummary(product: product),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('QUANTITY'),
            const SizedBox(height: AppSpacing.md),
            _QuantityRow(
              qty: _qty,
              onMinus: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
              onPlus: () => setState(() => _qty = (_qty + 1).clamp(1, 99)),
            ),
            if (product.colors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader('SELECT COLOR'),
              const SizedBox(height: AppSpacing.md),
              _ColorPicker(
                colors: product.colors,
                selected: _color,
                onSelect: (c) => setState(() => _color = c),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('DELIVERY AREA'),
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.md),
            _DistrictDropdown(
              // Re-create the field per division so its internal value never
              // lingers from a previously-selected division's district list.
              key: ValueKey('dist-${_division?.id}'),
              districts: _districts,
              value: _district,
              loading: _loadingDist,
              enabled: _division != null,
              onChanged: (d) => setState(() => _district = d),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('FULL ADDRESS'),
            const SizedBox(height: AppSpacing.md),
            _Field(
              controller: _address,
              hint: 'House / road / area, city, post code…',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              keyboardType: TextInputType.streetAddress,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('PHONE NUMBER'),
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.xl),
            _OrderSummary(
              qty: _qty,
              subtotal: _subtotal,
              delivery: _delivery,
              total: _total,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 15, color: context.cTextMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cash on Delivery · ${taka(MockData.deliveryInsideDhaka)} inside Dhaka, '
                    '${taka(MockData.deliveryOutsideDhaka)} outside.',
                    style:
                        AppTextStyles.body2.copyWith(color: context.cTextMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Building blocks ───────────────────────────────────────────────────────

BoxDecoration _cardDeco(BuildContext context) => BoxDecoration(
      color: context.cSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.cBorder),
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
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 90,
              height: 90,
              color: AppColors.primary.withValues(alpha: 0.08),
              child: product.image != null
                  ? Image.asset(product.image!,
                      fit: BoxFit.cover,
                      cacheWidth: 260,
                      errorBuilder: (_, __, ___) => Icon(product.icon,
                          size: 40, color: AppColors.primary))
                  : Icon(product.icon, size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(taka(product.price),
                        style: AppTextStyles.h2.copyWith(
                            fontSize: 19, color: AppColors.matchesGreen)),
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
                const SizedBox(height: 8),
                const StatusPill(
                    text: 'In Stock', color: AppColors.matchesGreen),
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
      padding: const EdgeInsets.all(8),
      decoration: _cardDeco(context),
      child: Row(
        children: [
          _StepBtn(icon: Icons.remove_rounded, onTap: onMinus),
          Expanded(
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(fontSize: 18)),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onPlus),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final sel = c == selected;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : context.cSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: sel ? AppColors.primary : context.cBorder,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _swatch(c),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(c,
                    style: AppTextStyles.title.copyWith(
                        fontSize: 13,
                        color: sel ? context.cText : context.cTextDim)),
                if (sel) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.primary),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Division dropdown — populated live from the BD geo API. Shows a spinner while
/// loading and a retry row if the request fails.
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
    // Smoothly cross-fade between the error/retry row and the live dropdown as
    // the real async division load resolves or fails — no hard flicker.
    return CrossFade(
      showFirst: error,
      first: _RetryRow(label: 'Failed to load divisions', onRetry: onRetry),
      second: DropdownButtonFormField<BdDivision>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: context.cSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      icon: loading
          ? const _MiniSpinner()
          : const Icon(Icons.keyboard_arrow_down_rounded),
      style: AppTextStyles.body1.copyWith(color: context.cText, fontSize: 15),
      decoration: InputDecoration(
        hintText: loading ? 'Loading divisions…' : 'Select division',
        prefixIcon: const Icon(Icons.map_outlined),
        fillColor: context.cSurface,
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

/// District dropdown — cascades from the selected division. Disabled until a
/// division is chosen.
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      icon: loading
          ? const _MiniSpinner()
          : const Icon(Icons.keyboard_arrow_down_rounded),
      style: AppTextStyles.body1.copyWith(color: context.cText, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.location_city_outlined),
        fillColor: context.cSurface,
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

/// A small inline spinner sized to sit in a field's trailing icon slot.
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

/// Tappable error row offering a retry (shown if the divisions request fails).
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
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
        fillColor: context.cSurface,
        alignLabelWithHint: true,
        prefixIcon: Padding(
          // Keep the icon at the top on the multi-line address field.
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 44 : 0),
          child: Icon(icon),
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
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(context),
      child: Column(
        children: [
          _row(context, 'Subtotal ($qty item${qty > 1 ? 's' : ''})',
              taka(subtotal)),
          const SizedBox(height: 10),
          _row(context, 'Delivery charge',
              delivery == 0 ? 'Select division' : taka(delivery),
              dim: delivery == 0),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.cBorder),
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
                ? AppTextStyles.title.copyWith(fontSize: 15)
                : AppTextStyles.body1.copyWith(color: context.cTextDim)),
        Text(value,
            style: emphasize
                ? AppTextStyles.h2
                    .copyWith(fontSize: 18, color: AppColors.matchesGreen)
                : AppTextStyles.title.copyWith(
                    fontSize: 13.5,
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
        color: context.cSurface,
        border: Border(top: BorderSide(color: context.cBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Payable',
                      style: AppTextStyles.body2
                          .copyWith(color: context.cTextDim)),
                  const SizedBox(height: 2),
                  Text(taka(total),
                      style: AppTextStyles.h2.copyWith(fontSize: 20)),
                ],
              ),
              const SizedBox(width: 14),
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
    );
  }
}
