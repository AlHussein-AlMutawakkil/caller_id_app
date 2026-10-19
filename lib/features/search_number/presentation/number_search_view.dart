import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث بالرقم', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                context.read<SearchNumberCubit>().search(value);
              },
              decoration: InputDecoration(
                hintText: 'أدخل رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    context.read<SearchNumberCubit>().search('');
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchNumberCubit, SearchNumberState>(
              builder: (context, state) {
                if (state is SearchNumberLoading) {
                  return const Center(child: SmartSearchIndicator(statusText: 'جاري البحث في قاعدة البيانات...',));
                }

                if (state is SearchNumberError) {
                  return Center(
                    child: Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                  );
                }

                if (state is SearchNumberSuccess) {
                  if (state.results.isEmpty) {
                    return const Center(
                      child: Text('لا توجد نتائج مطابقة', style: TextStyle(fontFamily: 'Cairo')),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final item = state.results[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(item.name, style: const TextStyle(fontFamily: 'Cairo')),
                          subtitle: Text(item.phone),
                        ),
                      );
                    },
                  );
                }

                return const Center(
                  child: Text('ابدأ بكتابة الرقم للبحث', style: TextStyle(fontFamily: 'Cairo')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}