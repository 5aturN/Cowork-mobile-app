import '../models/transaction_model.dart';

abstract class WalletRepository {
  Future<void> createTransaction(TransactionModel transaction);
  Stream<List<TransactionModel>> getTransactions(String userId);
}
