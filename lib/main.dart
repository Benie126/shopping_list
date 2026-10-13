import 'package:flutter/material.dart';

class Item {
  Item(this.name, {this.category = 'Food', this.note = ''});

  String name;
  bool bought = false;
  String category;
  String note;
  int quantity = 1;
}

void main() {
  runApp(const ShoppingApp());
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(title: 'Shopping List'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final items = <Item>[
    Item('Milk', category: 'Food'),
    Item('Bread', category: 'Food'),
    Item('Rice', category: 'Food'),
  ];
  final controller = TextEditingController();
  String selectedCategory = 'Food';
  String filter = 'All';

  static const categories = ['Food', 'Drinks', 'Home'];
  static const filters = ['All', 'To buy', 'Bought'];

  // ---------- helpers ----------

  List<Item> get visibleItems {
    List<Item> list;
    switch (filter) {
      case 'To buy':
        list = items.where((i) => !i.bought).toList();
        break;
      case 'Bought':
        list = items.where((i) => i.bought).toList();
        break;
      default:
        list = [...items];
        list.sort((a, b) {
          if (a.bought == b.bought) return 0;
          return a.bought ? 1 : -1;
        });
    }
    return list;
  }

  // ---------- add ----------

  void addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type an item first')),
      );
      return;
    }

    final existing = items.firstWhere(
          (i) => i.name.toLowerCase() == text.toLowerCase(),
      orElse: () => Item(''),
    );

    if (existing.name.isNotEmpty) {
      setState(() {
        existing.quantity += 1;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${existing.name} is already on the list: now ×${existing.quantity}',
          ),
        ),
      );
    } else {
      setState(() {
        items.add(Item(text, category: selectedCategory));
      });
    }
    controller.clear();
  }

  // ---------- delete / undo ----------

  void deleteItem(Item item) {
    final index = items.indexOf(item);
    if (index == -1) return;
    final removed = items.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.name} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              items.insert(index, removed);
            });
          },
        ),
      ),
    );
  }

  void deleteAll() {
    if (items.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all?'),
        content: Text('Remove all ${items.length} items from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => items.clear());
              Navigator.pop(context);
            },
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
  }

  void clearBought() {
    final boughtCount = items.where((i) => i.bought).length;
    if (boughtCount == 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bought items to clear')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear bought items?'),
        content: Text('Remove $boughtCount bought item(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                items.removeWhere((i) => i.bought);
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // ---------- EDIT dialog (your original feature, kept) ----------

  void editItem(Item item) {
    final editController = TextEditingController(text: item.name);
    String editCategory = item.category;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: editCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => editCategory = v);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final newName = editController.text.trim();
                    if (newName.isEmpty) return;
                    setState(() {
                      item.name = newName;
                      item.category = editCategory;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- DETAILS screen ----------

  void openDetails(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsScreen(item: item)),
    ).then((_) {
      setState(() {});
    });
  }

  // ---------- category visual helpers ----------

  IconData categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Drinks':
        return Icons.local_drink;
      case 'Home':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  Color categoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Drinks':
        return Colors.blue;
      case 'Home':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget categoryChip(String category) {
    final color = categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------- lifecycle ----------

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final leftCount = items.where((i) => !i.bought).length;
    final boughtCount = items.length - leftCount;
    final visible = visibleItems;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              '$leftCount left · $boughtCount bought',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear bought items',
            onPressed: clearBought,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete all',
            onPressed: deleteAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'New item',
                          prefixIcon: Icon(Icons.add_shopping_cart),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => addItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: addItem,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Category:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: categories
                            .map(
                              (c) => ButtonSegment(
                            value: c,
                            label: Text(c),
                            icon: Icon(categoryIcon(c), size: 16),
                          ),
                        )
                            .toList(),
                        selected: {selectedCategory},
                        onSelectionChanged: (s) {
                          setState(() => selectedCategory = s.first);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Show:'),
                    const SizedBox(width: 12),
                    ...filters.map(
                          (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: filter == f,
                          onSelected: (_) {
                            setState(() => filter = f);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? _emptyState(
                'Your list is empty', 'Add an item above to get started')
                : visible.isEmpty
                ? _emptyState('Nothing here', 'Try another filter')
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final item = visible[index];
                return Dismissible(
                  key: ObjectKey(item),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => deleteItem(item),
                  child: Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: Icon(
                        item.bought
                            ? Icons.check_circle
                            : categoryIcon(item.category),
                        color: item.bought
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          decoration: item.bought
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: item.bought ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          categoryChip(item.category),
                          if (item.note.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '· ${item.note}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          item.bought = !item.bought;
                        });
                      },
                      onLongPress: () => openDetails(item),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              setState(() {
                                if (item.quantity > 1) {
                                  item.quantity -= 1;
                                }
                              });
                            },
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              setState(() {
                                item.quantity += 1;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => editItem(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => deleteItem(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ---------- Details screen (separate page) ----------

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.item});

  final Item item;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late TextEditingController nameController;
  late TextEditingController noteController;
  late String category;

  static const categories = ['Food', 'Drinks', 'Home'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    noteController = TextEditingController(text: widget.item.note);
    category = widget.item.category;
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void save() {
    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    setState(() {
      widget.item.name = newName;
      widget.item.note = noteController.text.trim();
      widget.item.category = category;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (e.g. 1 litre bottle)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.map((c) {
                return ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) {
                    setState(() => category = c);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: save,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}