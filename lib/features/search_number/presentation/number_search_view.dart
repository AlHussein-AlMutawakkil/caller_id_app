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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<SearchNumberCubit>().search(query);
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
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.Secondary,
                  prefixIcon:
                      const Icon(Icons.dialpad, color: AppColors.primary),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                            });
                          },
                        )
                      : null,
                  hintText: 'أدخل رقم الهاتف المراد البحث عنه...',
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
              // زر البحث بالرقم المطلوب
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                  return const Center(
                    child: Text(
                      'لا توجد نتائج مطابقة',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                // عرض نتائج البحث في بطاقة موحدة بخطوط فاصلة دقيقة (مطابقة للصورة 2)
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AppResultListContainer(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      for (final item in state.results)
                        AppResultTile(
                          name: item.name,
                          phone: item.phone,
                        ),
                    ],
                  ),
                );
              }

              return const Center(
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
