import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/app_sizes.dart';
import '../bloc/mail_bloc.dart';
import '../bloc/mail_event.dart';
import '../bloc/mail_state.dart';
import '../../domain/models/mail_item.dart';

class CartItemsList extends StatelessWidget {
  final List<MailItem> items;
  final String currency;
  final CartStatus status;

  const CartItemsList({
    super.key,
    required this.items,
    required this.currency,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: items
            .map((item) => _CartItemCard(
                  key: ValueKey(item.id),
                  item: item,
                  theme: theme,
                  currency: currency,
                  status: status,
                ))
            .toList(),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final MailItem item;
  final ThemeData theme;
  final String currency;
  final CartStatus status;

  const _CartItemCard({
    super.key,
    required this.item,
    required this.theme,
    required this.currency,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    double extras = item.extras.fold(
        0.0, (sum, e) => sum + ((e['price'] as num?)?.toDouble() ?? 0));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          AppSizes.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (item.size != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text("units.size_${item.size}".tr(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor, fontSize: 11)),
                  ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    if (item.originalPrice != null &&
                        item.originalPrice! + extras > item.price + extras)
                      Text(_formatPrice(item.originalPrice! + extras),
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: theme.hintColor,
                          )),
                    Text(_formatPrice(item.price + extras),
                        style: TextStyle(color: theme.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                _QuantityControls(item: item, status: status),
              ],
            ),
          ),
          _buildDeleteBtn(context),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: item.imagePath.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: item.imagePath,
              width: 70,
              height: 70,
              fit: BoxFit.cover)
          : Image.asset(
              item.imagePath.isEmpty
                  ? "assets/images/meals/burger.png"
                  : item.imagePath,
              width: 70,
              height: 70,
              fit: BoxFit.cover),
    );
  }

  Widget _buildDeleteBtn(BuildContext context) {
    return IconButton(
      onPressed: status == CartStatus.loading
          ? null
          : () => context.read<MailBloc>().add(RemoveItemEvent(
              id: item.id, restaurantId: item.restaurantId)),
      icon: const Icon(Icons.delete_outline,
          color: Colors.redAccent, size: 22),
    );
  }

  String _formatPrice(double price) {
    if (currency == "EUR" || currency == "€") {
      return "${price.toStringAsFixed(2)} €";
    }
    return "${price.toInt()} ${currency.isEmpty ? "ل.س" : currency}";
  }
}

class _QuantityControls extends StatelessWidget {
  final MailItem item;
  final CartStatus status;

  const _QuantityControls({required this.item, required this.status});

  @override
  Widget build(BuildContext context) {
    final disabled = status == CartStatus.loading;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: item.quantity == 1
                ? Icons.delete_outline
                : Icons.remove,
            onPressed: disabled
                ? null
                : () {
                    if (item.quantity == 1) {
                      context.read<MailBloc>().add(RemoveItemEvent(
                          id: item.id,
                          restaurantId: item.restaurantId));
                    } else {
                      context.read<MailBloc>().add(UpdateCartItemEvent(
                          itemId: item.id,
                          quantity: item.quantity - 1));
                    }
                  },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _QtyButton(
            icon: Icons.add,
            onPressed: disabled || item.quantity >= 50
                ? null
                : () {
                    context.read<MailBloc>().add(UpdateCartItemEvent(
                        itemId: item.id,
                        quantity: item.quantity + 1));
                  },
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}