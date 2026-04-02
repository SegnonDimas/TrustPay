import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../injection_container.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoryRepository _categoryRepository;
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoryRepository = sl<CategoryRepository>();
    _categoriesFuture = _categoryRepository.getCategories();
  }

  void _reload() {
    setState(() {
      _categoriesFuture = _categoryRepository.getCategories();
    });
  }

  Future<void> _createCategory() async {
    final nameController = TextEditingController();
    CategoryType selectedType = CategoryType.expense;
    final formKey = GlobalKey<FormState>();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle catégorie'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Nom requis'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CategoryType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: CategoryType.expense,
                          child: Text('Dépense'),
                        ),
                        DropdownMenuItem(
                          value: CategoryType.income,
                          child: Text('Revenu'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedType = value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );

    if (shouldCreate != true) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      await _categoryRepository.createCategory(
        name: nameController.text.trim(),
        type: selectedType,
      );
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catégorie créée.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec création catégorie: $e')),
      );
    }
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _categoryRepository.deleteCategory(category.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec suppression: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurer catégories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCategory,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur chargement: ${snapshot.error}'));
          }

          final categories = snapshot.data ?? const <Category>[];
          if (categories.isEmpty) {
            return const Center(child: Text('Aucune catégorie.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = categories[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    c.type == CategoryType.income ? 'Revenu' : 'Dépense',
                  ),
                  trailing: c.isDefault
                      ? const Icon(Icons.lock_outline, color: Colors.grey)
                      : IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _deleteCategory(c),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
