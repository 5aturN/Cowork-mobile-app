import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _supabase;

  WalletRepositoryImpl(this._supabase);

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    try {
      await _supabase.from('transactions').insert(transaction.toJson());
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  @override
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false) // Newest first
        .map((data) {
          final transactions =
              data.map((e) => TransactionModel.fromJson(e)).toList();
          // Sort client-side to ensure newest first
          transactions.sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!); // Descending
          });
          return transactions;
        });
  }
}
