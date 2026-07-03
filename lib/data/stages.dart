/// Static data for the 20 monster evolution stages.
///
/// Per the user's decision, monsters are represented by emoji rather than
/// bundled image files. Each stage has a distinct emoji so the evolution
/// reads as visual progress, plus a short flavour name shown in the UI.
library;

/// Total number of evolution stages (spec 1.3).
const int kMaxStage = 20;

/// Mandatory cooldown between evolutions, in seconds (spec 1.3 / 2.3).
const int kCooldownSeconds = 60;

/// Emoji shown for each stage. Index `i` corresponds to stage `i + 1`.
///
/// The arc goes egg -> hatchling -> beast -> apex dragon so that pressing
/// "Evolve" feels like meaningful progression toward stage 20.
const List<String> stageEmojis = <String>[
  '🥚', // 1  - egg
  '🐣', // 2  - hatching
  '🐤', // 3  - chick
  '🐛', // 4  - larva
  '🐌', // 5  - crawler
  '🦗', // 6  - hopper
  '🦎', // 7  - reptile
  '🐍', // 8  - serpent
  '🐢', // 9  - shelled
  '🦂', // 10 - stinger
  '🦀', // 11 - clawed
  '🐙', // 12 - tentacled
  '🦈', // 13 - predator
  '🐊', // 14 - crocodilian
  '🦖', // 15 - raptor
  '🦕', // 16 - titan
  '🐉', // 17 - young dragon
  '🐲', // 18 - dragon lord
  '👹', // 19 - demon form
  '🔥', // 20 - apex / final
];

/// Short flavour name for each stage (index `i` == stage `i + 1`).
const List<String> stageNames = <String>[
  'Egg',
  'Hatchling',
  'Chick',
  'Larva',
  'Crawler',
  'Hopper',
  'Reptile',
  'Serpent',
  'Shelled One',
  'Stinger',
  'Clawed One',
  'Tentacled',
  'Predator',
  'Crocodilian',
  'Raptor',
  'Titan',
  'Young Dragon',
  'Dragon Lord',
  'Demon Form',
  'Apex Monster',
];

/// Emoji for a 1-based [stage] value (clamped to the valid range).
String emojiForStage(int stage) => stageEmojis[stage.clamp(1, kMaxStage) - 1];

/// Flavour name for a 1-based [stage] value (clamped to the valid range).
String nameForStage(int stage) => stageNames[stage.clamp(1, kMaxStage) - 1];
