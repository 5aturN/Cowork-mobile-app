import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/models/transaction_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(Supabase.instance.client);
});

final userTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.session?.user.id;

  if (userId == null) return Stream.value([]);
  return ref.watch(walletRepositoryProvider).getTransactions(userId);
});
