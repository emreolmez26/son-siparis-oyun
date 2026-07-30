import 'card_definition.dart';

class ServiceCompletion {
  const ServiceCompletion({
    required this.orderId,
    required this.customerId,
    required this.rewardCoins,
    required this.requestedResultType,
  });

  final String orderId;
  final String customerId;
  final int rewardCoins;
  final CardType requestedResultType;
}
