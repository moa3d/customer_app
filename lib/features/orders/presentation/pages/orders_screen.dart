import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// استيراد المجلد المنظم للـ Bloc
import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/app_sizes.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../cart/presentation/bloc/mail_bloc.dart';
import '../../../cart/presentation/bloc/mail_event.dart';
import '../../../cart/presentation/bloc/mail_state.dart';

// استيراد الويدجت التي سنطابقها بالأسفل
import '../../data/repositories/order_repository.dart';
import '../widgets/order_card_item.dart';
import '../widgets/history_card_item.dart';

class OrdersScreen extends StatefulWidget {
  final bool isFull;
  final Function(int)? movePage;

  const OrdersScreen({super.key, required this.isFull, this.movePage});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTab = 0;
  StreamSubscription<Map<String, dynamic>>? _orderStatusSub;

  /// آخر رسالة خطأ عُرضت — لتجنب تكرار نفس التوست
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    // جلب البيانات الأولية
    _refreshData();

    // الاستماع للسوكيت لتحديث الحالات فورياً
    _orderStatusSub = SocketService().listenToOrderStatus((data) {
      if (mounted) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("status_updated_msg".tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _orderStatusSub?.cancel();
    super.dispose();
  }

  void _refreshData() {
    context.read<MailBloc>().add(FetchUserOrdersEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<MailBloc, MailState>(
      listener: (context, state) {
        final String? toast = state.toast;
        if (toast != null && toast.isNotEmpty) {
          _showSnack(context, toast, isError: false);
          context.read<MailBloc>().add(ClearToastEvent());
          return;
        }
        if (state.status == CartStatus.success) {
          _lastShownError = null;
        }
        if (state.status == CartStatus.error &&
            state.errorMessage != null &&
            state.errorMessage!.isNotEmpty &&
            state.errorMessage != _lastShownError) {
          _lastShownError = state.errorMessage;
          _showSnack(context, state.errorMessage!, isError: true);
        }
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: _buildHeader(theme),
        ),
      ),
      body: BlocBuilder<MailBloc, MailState>(
        builder: (context, state) {
          if (state.status == CartStatus.loading && state.orders.isEmpty) {
            return const ShimmerOrdersList();
          }

          final allOrders = state.orders;

          // `not_confirmed` هي حالة طلب أُنشئ ولم يُرسل بعد: أُلغي الدفع، أو
          // انقطع السوكيت، أو انتهت مهلة الإرسال. وكان المرشّح سلبياً («كل ما
          // ليس مُسلَّماً ولا ملغى») فتظهر هذه الأشباح في «الطلبات الجارية»
          // حتى ينظّفها الباك عند إنشاء الطلب التالي. صار الترشيح إيجابياً
          // على الحالات الجارية فعلاً.
          final currentOrders = allOrders.where((o) =>
              OrderRepository.activeStatuses.contains(o['orderStatus'])).toList();

          final historyOrders = allOrders.where((o) =>
              o['orderStatus'] == 'delivered').toList();

          final cancelledOrders = allOrders.where((o) =>
              o['orderStatus'] == 'cancelled').toList();

          final List<dynamic> displayList;
          switch (_selectedTab) {
            case 1:
              displayList = historyOrders;
              break;
            case 2:
              displayList = cancelledOrders;
              break;
            default:
              displayList = currentOrders;
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: displayList.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
              key: ValueKey(_selectedTab),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final data = displayList[index];
                if (_selectedTab == 0) {
                  return OrderCardItem(
                    orderData: data,
                    // مؤشّر الإلغاء لبطاقته وحدها: كان مشتقاً من
                    // `status == loading` فيضيء على كل البطاقات مع أي تحديث.
                    isLoading: state.cancellingOrderId != null &&
                        state.cancellingOrderId == data['_id'],
                    onCancel: () =>
                        context.read<MailBloc>().add(
                        CancelOrderEvent(data['_id'])),
                    onRefresh: _refreshData,
                  );
                }
                return HistoryCardItem(
                  orderData: data,
                  showRating: _selectedTab != 2,
                  onRefresh: _refreshData,
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          duration: Duration(seconds: isError ? 4 : 3),
        ),
      );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppSizes.radius32)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (widget.movePage != null) {
                        widget.movePage!(0);
                      } else {
                        StatefulNavigationShell.of(context).goBranch(0);
                      }
                    },
                    icon: Icon(Icons.adaptive.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('orders_title'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleTab(
                      'current_orders'.tr(),
                      _selectedTab == 0,
                      () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleTab(
                      'orders_history'.tr(),
                      _selectedTab == 1,
                      () => setState(() => _selectedTab = 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleTab(
                      'cancelled_orders'.tr(),
                      _selectedTab == 2,
                      () => setState(() => _selectedTab = 2),
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

  Widget _buildToggleTab(String title, bool active, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? theme.primaryColor : theme.hintColor.withValues(alpha: 
              0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(title, style: TextStyle(
              color: active ? Colors.white : theme.hintColor,
              fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80,
              color: theme.hintColor.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text('no_orders_title'.tr(), style: theme.textTheme.titleLarge),
          Text('no_orders_subtitle'.tr(),
              style: TextStyle(color: theme.hintColor)),
        ],
      ),
    );
  }
}