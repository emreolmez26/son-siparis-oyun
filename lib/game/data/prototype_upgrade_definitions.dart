import '../models/upgrade_definition.dart';
import '../models/upgrade_id.dart';

const prototypeUpgradeDefinitions = <UpgradeDefinition>[
  UpgradeDefinition(
    id: UpgradeId.fastPan,
    name: 'Hızlı Tava',
    description: 'Tava işlemleri %25 daha hızlı tamamlanır.',
    category: 'EKİPMAN',
    iconIdentifier: 'pan',
  ),
  UpgradeDefinition(
    id: UpgradeId.doubleCheese,
    name: 'Çifte Peynir',
    description: 'Peynir kullanılan tarifler +5 para kazandırır.',
    category: 'TARİF',
    iconIdentifier: 'cheese',
  ),
  UpgradeDefinition(
    id: UpgradeId.coolHeadedService,
    name: 'Soğukkanlı Servis',
    description: 'Mükemmel servisten sonra sıradaki müşterinin sabrı artar.',
    category: 'SERVİS',
    iconIdentifier: 'service',
  ),
];
