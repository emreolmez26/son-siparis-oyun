import 'card_definition.dart';

enum OrderStatus { active, completed, failed, closed }

class OrderState {
  const OrderState({
    required this.id,
    required this.requestedResultType,
    required this.status,
  });

  final String id;
  final CardType requestedResultType;
  final OrderStatus status;

  OrderState copyWith({
    String? id,
    CardType? requestedResultType,
    OrderStatus? status,
  }) => OrderState(
    id: id ?? this.id,
    requestedResultType: requestedResultType ?? this.requestedResultType,
    status: status ?? this.status,
  );
}
