import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/wallet_provider.dart';
import '../widgets/transaction_card.dart';

class WalletHistoryPage extends ConsumerStatefulWidget {
  const WalletHistoryPage({super.key});

  @override
  ConsumerState<WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends ConsumerState<WalletHistoryPage> {
  String _selectedType = 'all'; // 'all', 'deposit', 'payment', 'refund'
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(userTransactionsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('История операций'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Compact Header with Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Type Selector (Dropdown-like)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showTypeSelector,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getTypeLabel(_selectedType),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Date Picker Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedDateRange == null
                            ? theme.cardColor
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDateRange == null
                              ? theme.dividerColor.withValues(alpha: 0.5)
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: _selectedDateRange == null
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)
                                : theme.colorScheme.primary,
                          ),
                          if (_selectedDateRange != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('d MMM').format(_selectedDateRange!.start)} - ${DateFormat('d MMM').format(_selectedDateRange!.end)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () =>
                                  setState(() => _selectedDateRange = null),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // Filter Logic
                final filtered = transactions.where((t) {
                  // Type Filter
                  if (_selectedType != 'all' && t.type != _selectedType) {
                    return false;
                  }
                  // Date Filter
                  if (_selectedDateRange != null && t.createdAt != null) {
                    final date = t.createdAt!;
                    // Include the end date fully
                    final end = _selectedDateRange!.end
                        .add(const Duration(days: 1))
                        .subtract(const Duration(milliseconds: 1));
                    if (date.isBefore(_selectedDateRange!.start) ||
                        date.isAfter(end)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 64,
                          color: theme.dividerColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Операций не найдено',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return TransactionCard(transaction: filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'deposit':
        return 'Пополнения';
      case 'payment':
        return 'Оплаты';
      case 'refund':
        return 'Возвраты';
      default:
        return 'Все операции';
    }
  }

  void _showTypeSelector() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildTypeOption('all', 'Все операции', Icons.list),
            _buildTypeOption('deposit', 'Пополнения', Icons.add_circle_outline),
            _buildTypeOption('payment', 'Оплаты', Icons.credit_card),
            _buildTypeOption('refund', 'Возвраты', Icons.assignment_return),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String label, IconData icon) {
    final isSelected = _selectedType == value;
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        setState(() => _selectedType = value);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: Theme.of(context).scaffoldBackgroundColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() => _selectedDateRange = result);
    }
  }
}
