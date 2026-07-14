/// Static data for the 15 monster evolution stages.
///
/// Per the user's decision, monsters are represented by emoji rather than
/// bundled image files. The stages form a single, coherent creature line — a
/// dragon — so pressing "Evolve" reads as the *same* creature growing up rather
/// than swapping to an unrelated icon.
///
/// The arc: egg -> hatchling -> reptilian juvenile forms -> true winged dragon
/// -> an epic elemental/cosmic dragon at the summit (cute -> epic). Emoji only
/// ships two literal dragon glyphs (🐲 young, 🐉 adult), so the final six
/// "epic" stages show the same dragon mastering an element — the flavour names
/// keep the creature's identity ("… Dragon" / "… Wyrm").
library;

/// Total number of evolution stages.
const int kMaxStage = 15;

/// Emoji shown for each stage. Index `i` corresponds to stage `i + 1`.
const List<String> stageEmojis = <String>[
  '🥚', // 1  - egg
  '🐣', // 2  - hatchling emerging
  '🦎', // 3  - tiny dragonling
  '🐍', // 4  - serpentling
  '🐊', // 5  - snapjaw saurian
  '🦕', // 6  - long-necked juvenile
  '🦖', // 7  - fanged ravager
  '🐲', // 8  - young dragon (horns & wings emerge)
  '🐉', // 9  - full winged dragon
  '🔥', // 10 - inferno dragon (breath awakens)
  '⚡', // 11 - storm dragon
  '🌋', // 12 - volcanic wyrm
  '🌊', // 13 - leviathan wyrm
  '☄️', // 14 - astral dragon
  '🌌', // 15 - cosmic dragon / final
];

/// Short flavour name for each stage (index `i` == stage `i + 1`).
const List<String> stageNames = <String>[
  'Mystery Egg',
  'Hatchling',
  'Dragonling',
  'Serpentling',
  'Snapjaw',
  'Juvenile Wyrm',
  'Fanged Ravager',
  'Young Dragon',
  'Winged Dragon',
  'Inferno Dragon',
  'Storm Dragon',
  'Volcanic Wyrm',
  'Leviathan Wyrm',
  'Astral Dragon',
  'Cosmic Dragon',
];

/// Emoji for a 1-based [stage] value (clamped to the valid range).
String emojiForStage(int stage) => stageEmojis[stage.clamp(1, kMaxStage) - 1];

/// Flavour name for a 1-based [stage] value (clamped to the valid range).
String nameForStage(int stage) => stageNames[stage.clamp(1, kMaxStage) - 1];
