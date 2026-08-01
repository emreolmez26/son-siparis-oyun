# Son Sipariş — Main Menu Handoff

## Goal
Implement only the Main Menu visual redesign in Flutter/Flame, using the supplied background asset and the approved Stitch target as the visual reference.

## Source of truth
- Current implementation is the source of truth for behavior and navigation.
- Stitch target is the source of truth for visual style only.
- Do not invent new systems or features that do not already exist in the game.

## Required features on this screen
Center actions:
1. VARDİYAYA BAŞLA
2. DEVAM ET — GÜN 5 (example active state)
3. GÜNÜN MÜCADELESİ

Bottom navigation:
- TARİF DEFTERİ
- MARKET
- AKTİF MUTFAK
- AYARLAR

Top-right info area:
- 1.250 PARA
- GÜN 5
- 3 / 3 PAKET
- GÜNLÜK REKOR: 8.420

## Screen type
- 1280x720 virtual game layout
- landscape
- mobile-game styled
- warm restaurant atmosphere
- readable on physical Android devices

## Visual style
- warm, cozy, bright restaurant game mood
- premium casual burger restaurant
- stylized / semi-illustrative feeling
- not a website hero image
- not overly dark
- UI-friendly readability

## Background
Use:
assets/ui/backgrounds/main_menu_restaurant.png
(or .webp if that is the saved file)

Do not redraw or approximate the background.
Use the supplied background asset directly.

## Main title
Title text:
SON SİPARİŞ

- centered
- large
- warm gold color
- bold
- visually similar to the Stitch target
- keep it clean and readable
- if no logo asset is provided, render as styled text

## Buttons
### Primary button
Text:
VARDİYAYA BAŞLA

Style:
- strongest emphasis
- gold fill
- dark text
- rounded corners
- subtle shadow
- mobile tap-friendly

### Secondary button
Text:
DEVAM ET — GÜN 5

Style:
- darker fill
- lighter text
- still readable and prominent

### Tertiary challenge button
Text:
GÜNÜN MÜCADELESİ

Style:
- smaller than primary
- darker / accent style
- visible but not stronger than Start Shift button

## Bottom navigation style
- small icon + label blocks
- visually game-like, not plain app-tab-bar
- warm brown / gold visual identity
- active item: AKTİF MUTFAK in the provided target
- labels must remain in Turkish

## Do not add
- player level
- avatar/profile
- quests/goals system if not already wired to this menu
- ads
- new currencies
- fake lock states
- extra widgets not visible in the real game flow

## Constraints
- Do not change save logic
- Do not change Market logic
- Do not change Daily Challenge logic
- Do not change gameplay systems
- Do not redesign other screens
- Stop after Main Menu implementation

## Deliverables
- Updated main menu UI in the game
- Any asset registration needed in pubspec.yaml
- Short implementation summary
- Android emulator screenshot of the final menu