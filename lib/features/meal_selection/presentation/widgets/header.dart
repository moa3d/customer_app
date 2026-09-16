import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nomnow_app/features/favorite/cubit/favorite_state.dart';

import '../../../favorite/cubit/favorite_cubit.dart';
import '../../../restaurant/data/models/meal.dart';

Widget buildFeaturedItem({
  required BuildContext context,
  required String imagePath,
  required VoidCallback onBack,
  required String time,
  required Meal meal, 
  bool isNetwork = true,
}) {
  final theme = Theme.of(context);

  return GestureDetector(
    onTap: () {},
    child: SizedBox(
      height: 325,
      child: Stack(
        children: [
          // الصورة (Network أو Asset)
          isNetwork
              ? CachedNetworkImage(
            imageUrl: imagePath,
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              color: theme.dividerColor.withValues(alpha: 0.1),
              child: const Icon(Icons.fastfood, size: 50),
            ),
          )
              : Image.asset(
            imagePath,
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.fill,
          ),

          // زر المفضلة المربوط مع الباك أند
          Positioned(
            top: 50,
            left: 16,
            child: BlocBuilder<FavoriteCubit, FavoriteState>(
              builder: (context, state) {
                // التحقق من حالة المفضلة لهذه الوجبة تحديداً
                final bool isFavorite = context.read<FavoriteCubit>().isFavorite(meal.id);

                return GestureDetector(
                  onTap: () {
                    // استدعاء دالة التبديل (تحديث السيرفر والحالة محلياً)
                    context.read<FavoriteCubit>().toggleFavorite(meal);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.black,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),

          // زر العودة
          Positioned(
            top: 50,
            right: 16,
            child: Material(
              color: Colors.white38,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                side: BorderSide(width: 1, color: Colors.white),
              ),
              child: InkWell(
                onTap: onBack,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: const SizedBox(
                  height: 40,
                  width: 40,
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // شارة الوقت
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: theme.primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}