import '../game_layout.dart';
import '../models/card_definition.dart';
import '../models/customer_definition.dart';
import '../models/customer_slot_state.dart';
import '../models/customer_state.dart';
import '../models/order_state.dart';
import '../models/service_completion.dart';
import '../systems/order_result_generator.dart';
import 'gameplay_session_state.dart';
import 'kitchen_table_state.dart';
import 'shift_state.dart';

class OrderSystem {
  OrderSystem({
    CustomerDefinition? customerDefinition,
    Iterable<CustomerDefinition>? customerDefinitions,
    OrderResultGenerator? orderGenerator,
  }) : _orderGenerator = orderGenerator ?? OrderResultGenerator(),
       slots = List<CustomerSlotState>.unmodifiable(
         (customerDefinitions ?? [customerDefinition!]).map(
           (definition) => CustomerSlotState(definition: definition),
         ),
       ) {
    if (slots.isEmpty) {
      throw ArgumentError.value(customerDefinitions, 'customerDefinitions');
    }
    startShift();
  }

  OrderResultGenerator _orderGenerator;
  final List<CustomerSlotState> slots;
  int _nextOrderSequence = 1;
  String? _tutorialProtectedCustomerId;

  /// Compatibility accessors for the original one-customer prototype.
  CustomerState get customer => slots.first.customer;
  OrderState get activeOrder => slots.first.order!;

  CustomerSlotState? slotForId(String customerId) {
    for (final slot in slots) {
      if (slot.definition.id == customerId) return slot;
    }
    return null;
  }

  List<CustomerSlotState> get activeSlots =>
      slots.where((slot) => slot.hasActiveOrder).toList(growable: false);

  void configureGenerator(OrderResultGenerator generator) {
    _orderGenerator = generator;
  }

  void startShift({
    bool tutorialFirstOrder = false,
    OrderResultGenerator? generator,
  }) {
    if (generator != null) _orderGenerator = generator;
    _tutorialProtectedCustomerId = null;
    for (final slot in slots) {
      _beginGeneratedOrder(
        slot,
        totalPatienceSeconds: slot.definition.basePatienceSeconds,
      );
    }
    if (tutorialFirstOrder) {
      final tutorialSlot = slots.first;
      _beginOrderWithResult(
        tutorialSlot,
        requestedResultType: CardType.classicBurger,
        totalPatienceSeconds: tutorialSlot.definition.basePatienceSeconds,
      );
      _tutorialProtectedCustomerId = tutorialSlot.definition.id;
    }
  }

  bool get tutorialPatienceProtectionActive =>
      _tutorialProtectedCustomerId != null;

  void clearTutorialPatienceProtection() {
    _tutorialProtectedCustomerId = null;
  }

  bool canServeDefinition(CardDefinition definition) =>
      matchingSlotsForDefinition(definition).isNotEmpty;

  List<CustomerSlotState> matchingSlotsForDefinition(
    CardDefinition definition,
  ) {
    final matching = <({CustomerSlotState slot, int index})>[];
    for (final entry in slots.indexed) {
      final slot = entry.$2;
      if (slot.hasActiveOrder &&
          slot.order!.requestedResultType == definition.type) {
        matching.add((slot: slot, index: entry.$1));
      }
    }
    matching.sort((left, right) {
      final byUrgency = left.slot.patience.normalizedRemaining.compareTo(
        right.slot.patience.normalizedRemaining,
      );
      return byUrgency != 0 ? byUrgency : left.index.compareTo(right.index);
    });
    return matching.map((entry) => entry.slot).toList(growable: false);
  }

  ServiceCompletion? tryServe({
    required String cardId,
    required KitchenTableState tableState,
    ShiftState? shiftState,
    GameplaySessionState? sessionState,
    int rewardCoins = GameLayout.successfulServiceRewardCoins,
    bool enterShiftFeedback = true,
  }) {
    final definition = tableState.definitionFor(cardId);
    final matchingSlots = matchingSlotsForDefinition(definition);
    if (matchingSlots.isEmpty || !tableState.canMarkCardServed(cardId)) {
      return null;
    }
    if (shiftState != null) {
      if (!shiftState.recordSuccessfulService(
        rewardCoins: rewardCoins,
        enterFeedback: enterShiftFeedback,
      )) {
        return null;
      }
    } else if (sessionState != null) {
      sessionState.recordSuccessfulService();
    } else {
      throw ArgumentError('A shift state is required for service.');
    }

    final slot = matchingSlots.first;
    tableState.markCardServed(cardId);
    slot.beginServiceFeedback(GameLayout.serviceFeedbackDurationSeconds);
    return ServiceCompletion(
      orderId: slot.order!.id,
      customerId: slot.definition.id,
      rewardCoins: rewardCoins,
      requestedResultType: definition.type,
      remainingPatienceSeconds: slot.patience.remainingSeconds,
    );
  }

  bool failCustomer(String customerId) {
    final slot = slotForId(customerId);
    if (slot == null || !slot.hasActiveOrder) return false;
    slot.beginFailureFeedback(GameLayout.failureFeedbackDurationSeconds);
    return true;
  }

  /// Compatibility helper for the original first customer path.
  bool failActiveOrder() => failCustomer(slots.first.definition.id);

  List<CustomerSlotState> advancePatience(double deltaSeconds) {
    final expired = <CustomerSlotState>[];
    for (final slot in activeSlots) {
      if (slot.definition.id == _tutorialProtectedCustomerId) continue;
      if (slot.advancePatience(deltaSeconds)) expired.add(slot);
    }
    return expired;
  }

  List<CustomerSlotState> advanceFeedback(double deltaSeconds) {
    final refills = <CustomerSlotState>[];
    for (final slot in slots) {
      if (slot.advanceFeedback(deltaSeconds)) refills.add(slot);
    }
    return refills;
  }

  void refillCustomer(
    String customerId, {
    required double totalPatienceSeconds,
  }) {
    final slot = slotForId(customerId);
    if (slot == null) return;
    _beginGeneratedOrder(slot, totalPatienceSeconds: totalPatienceSeconds);
  }

  void closeActiveOrder() {
    for (final slot in activeSlots) {
      slot.order = slot.order!.copyWith(status: OrderStatus.closed);
    }
  }

  /// Compatibility helper for the original first customer path.
  void beginNextOrder() => refillCustomer(
    slots.first.definition.id,
    totalPatienceSeconds: slots.first.definition.basePatienceSeconds,
  );

  void _beginGeneratedOrder(
    CustomerSlotState slot, {
    required double totalPatienceSeconds,
  }) {
    final activeTypes = slots
        .where((candidate) => candidate != slot && candidate.hasActiveOrder)
        .map((candidate) => candidate.order!.requestedResultType);
    final requestedResultType = _orderGenerator.nextResult(
      activeResults: activeTypes,
    );
    _beginOrderWithResult(
      slot,
      requestedResultType: requestedResultType,
      totalPatienceSeconds: totalPatienceSeconds,
    );
  }

  void _beginOrderWithResult(
    CustomerSlotState slot, {
    required CardType requestedResultType,
    required double totalPatienceSeconds,
  }) {
    final order = OrderState(
      id: 'order_${_nextOrderSequence.toString().padLeft(2, '0')}',
      requestedResultType: requestedResultType,
      status: OrderStatus.active,
    );
    _nextOrderSequence++;
    slot.beginOrder(order, totalPatienceSeconds: totalPatienceSeconds);
  }
}
