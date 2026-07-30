import 'customer_definition.dart';
import 'customer_patience_state.dart';
import 'customer_state.dart';
import 'order_state.dart';

enum CustomerFeedbackKind { none, service, failure }

class CustomerSlotState {
  CustomerSlotState({required this.definition})
    : customer = CustomerState(definition: definition),
      totalPatienceSeconds = definition.basePatienceSeconds;

  final CustomerDefinition definition;
  final CustomerState customer;
  OrderState? order;
  double totalPatienceSeconds;
  double _elapsedPatienceSeconds = 0;
  CustomerFeedbackKind feedbackKind = CustomerFeedbackKind.none;
  double _feedbackRemainingSeconds = 0;

  bool get hasActiveOrder => order?.status == OrderStatus.active;
  bool get hasFeedback => feedbackKind != CustomerFeedbackKind.none;
  double get feedbackRemainingSeconds => _feedbackRemainingSeconds;
  CustomerPatienceState get patience => CustomerPatienceState(
    elapsedSeconds: _elapsedPatienceSeconds,
    totalSeconds: totalPatienceSeconds,
  );

  void beginOrder(OrderState order, {required double totalPatienceSeconds}) {
    this.order = order;
    this.totalPatienceSeconds = totalPatienceSeconds;
    _elapsedPatienceSeconds = 0;
    feedbackKind = CustomerFeedbackKind.none;
    _feedbackRemainingSeconds = 0;
    customer.status = CustomerStatus.waiting;
  }

  bool advancePatience(double deltaSeconds) {
    if (!hasActiveOrder ||
        deltaSeconds <= 0 ||
        patience.status == CustomerPatienceStatus.expired) {
      return false;
    }
    _elapsedPatienceSeconds = (_elapsedPatienceSeconds + deltaSeconds)
        .clamp(0.0, totalPatienceSeconds)
        .toDouble();
    return patience.status == CustomerPatienceStatus.expired;
  }

  void beginServiceFeedback(double durationSeconds) {
    if (order == null) return;
    order = order!.copyWith(status: OrderStatus.completed);
    customer.status = CustomerStatus.served;
    feedbackKind = CustomerFeedbackKind.service;
    _feedbackRemainingSeconds = durationSeconds;
  }

  void beginFailureFeedback(double durationSeconds) {
    if (order == null) return;
    order = order!.copyWith(status: OrderStatus.failed);
    customer.status = CustomerStatus.disappointed;
    feedbackKind = CustomerFeedbackKind.failure;
    _feedbackRemainingSeconds = durationSeconds;
  }

  bool advanceFeedback(double deltaSeconds) {
    if (!hasFeedback || deltaSeconds <= 0) return false;
    _feedbackRemainingSeconds = (_feedbackRemainingSeconds - deltaSeconds)
        .clamp(0.0, double.infinity)
        .toDouble();
    return _feedbackRemainingSeconds <= 0;
  }
}
