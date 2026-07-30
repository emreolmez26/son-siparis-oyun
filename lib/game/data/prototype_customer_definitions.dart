import '../models/customer_definition.dart';

const regularCustomerDefinition = CustomerDefinition(
  id: 'customer_regular',
  displayName: 'Düzenli Müşteri',
  displayLabel: 'M1',
  basePatienceSeconds: 24,
  accentColorValue: 0xFF679E47,
);

const impatientCustomerDefinition = CustomerDefinition(
  id: 'customer_impatient',
  displayName: 'Sabırsız Müşteri',
  displayLabel: 'M2',
  basePatienceSeconds: 18,
  accentColorValue: 0xFFE08A3A,
);

const foodieCustomerDefinition = CustomerDefinition(
  id: 'customer_foodie',
  displayName: 'Gurme Müşteri',
  displayLabel: 'M3',
  basePatienceSeconds: 28,
  accentColorValue: 0xFF9C6BB2,
);

const prototypeCustomerDefinitions = <CustomerDefinition>[
  regularCustomerDefinition,
  impatientCustomerDefinition,
  foodieCustomerDefinition,
];

/// Compatibility alias retained for the original one-customer tests.
const prototypeCustomerDefinition = regularCustomerDefinition;
