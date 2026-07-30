import '../game_layout.dart';
import '../models/card_definition.dart';
import '../models/processing_definition.dart';
import '../models/processing_job.dart';
import 'prototype_card_definitions.dart';

const panProcessingDefinition = ProcessingDefinition(
  id: 'cook_patty',
  equipmentType: CardType.pan,
  inputType: CardType.patty,
  outputDefinition: cookedPattyCardDefinition,
  action: ProcessingAction.cookPatty,
  baseDurationSeconds: GameLayout.processingDurationSeconds,
);

const knifeProcessingDefinition = ProcessingDefinition(
  id: 'slice_tomato',
  equipmentType: CardType.knife,
  inputType: CardType.tomato,
  outputDefinition: slicedTomatoCardDefinition,
  action: ProcessingAction.sliceTomato,
  baseDurationSeconds: GameLayout.knifeProcessingDurationSeconds,
);

const fryerProcessingDefinition = ProcessingDefinition(
  id: 'fry_potato',
  equipmentType: CardType.fryer,
  inputType: CardType.potato,
  outputDefinition: crispyFriesCardDefinition,
  action: ProcessingAction.fryPotato,
  baseDurationSeconds: GameLayout.fryerProcessingDurationSeconds,
);

const prototypeProcessingDefinitions = <ProcessingDefinition>[
  panProcessingDefinition,
  knifeProcessingDefinition,
  fryerProcessingDefinition,
];
