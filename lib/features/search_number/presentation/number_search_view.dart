import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_result_card.dart';
import '../../../core/widgets/smart_search_indicator.dart';
import '../cubit/search_number_cubit.dart';
import '../cubit/search_number_state.dart';
import '../data/number_search_repository.dart';

class NumberSearchView extends StatelessWidget {
  const NumberSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchNumberCubit(NumberSearchRepository()),
      child: const _NumberSearchBody(),
    );
  }
}

class _NumberSearchBody extends StatefulWidget {
  const _NumberSearchBody();

  @override
  State<_NumberSearchBody> createState() => _NumberSearchBodyState();
}

class _NumberSearchBodyState extends State<_NumberSearchBody> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // إغلاق لوحة المفاتيح وسحب التركيز فوراً
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();

    context.read<SearchNumberCubit>().search(query);
  }

  Widget _buildResultsCountHeader(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppColors.isDarkMode ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_list_bulleted_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "نتائج البحث",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppColors.primary.withOpacity(AppColors.isDarkMode ? 0.2 : 0.08)
                  : AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count ${count == 1 ? 'اسم مسجل' : (count == 2 ? 'اسمان مسجلان' : 'أسماء مسجلة')}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: count > 0 ? AppColors.primary : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.phone_disabled_rounded,
            size: 46,
            color: AppColors.textSecondary.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            "لم يتم العثور على أي نتائج (0)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "هذا الرقم غير مسجل في قاعدة البيانات الحالية",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: false,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.Secondary,
                  prefixIcon:
                      Icon(Icons.dialpad, color: AppColors.primary),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                            });
                          },
                        )
                      : null,
                  hintText: 'أدخل رقم الهاتف المراد البحث عنه...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _performSearch,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "بحث بالرقم",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<SearchNumberCubit, SearchNumberState>(
            builder: (context, state) {
              if (state is SearchNumberLoading) {
                return const Center(
                  child: SmartSearchIndicator(
                    statusText: 'جاري البحث في قاعدة البيانات...',
                  ),
                );
              }

              if (state is SearchNumberError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                );
              }

              if (state is SearchNumberSuccess) {
                if (state.results.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildEmptyResultsIndicator(),
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      _buildResultsCountHeader(state.results.length),
                      AppResultListContainer(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          for (final item in state.results)
                            AppResultTile(
                              name: item.name,
                              phone: item.phone,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: Text(
                  'أدخل رقم الهاتف واضغط على بحث بالرقم',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
