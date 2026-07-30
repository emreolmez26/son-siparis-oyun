import 'customer_definition.dart';

enum CustomerStatus { waiting, served, disappointed }

class CustomerState {
  CustomerState({
    required this.definition,
    this.status = CustomerStatus.waiting,
  });

  final CustomerDefinition definition;
  CustomerStatus status;
}
