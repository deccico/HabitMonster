/// Static data for the 50 monster evolution stages.
///
/// Per the user's decision, monsters are represented by emoji rather than
/// bundled image files. Each stage has a distinct emoji so the evolution
/// reads as visual progress, plus a short flavour name shown in the UI.
library;

/// Total number of evolution stages.
const int kMaxStage = 50;

/// Emoji shown for each stage. Index `i` corresponds to stage `i + 1`.
///
/// The arc goes egg -> hatchling -> beast -> dragon -> undead -> giant ->
/// mythic -> elemental -> cosmic so that pressing "Evolve" feels like
/// meaningful progression toward stage 50.
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
  '🔥', // 20 - apex monster
  '👺', // 21 - goblin king
  '💀', // 22 - bone fiend
  '👻', // 23 - phantom
  '🧟', // 24 - revenant
  '🧛', // 25 - vampire lord
  '🦇', // 26 - night terror
  '🐺', // 27 - dire wolf
  '🕷️', // 28 - widow fiend
  '🦑', // 29 - kraken spawn
  '🐋', // 30 - leviathan
  '🦏', // 31 - juggernaut
  '🦛', // 32 - behemoth
  '🐘', // 33 - colossus
  '🦣', // 34 - tusked titan
  '🦬', // 35 - thunder beast
  '🦍', // 36 - ape king
  '🗿', // 37 - stone golem
  '🦄', // 38 - mythic steed
  '❄️', // 39 - frost wraith
  '⚡', // 40 - storm spirit
  '🌪️', // 41 - tempest fiend
  '🌋', // 42 - magma titan
  '🌊', // 43 - abyss caller
  '👽', // 44 - star being
  '👾', // 45 - void invader
  '☄️', // 46 - comet crusher
  '🪐', // 47 - world eater
  '💫', // 48 - star devourer
  '🌟', // 49 - celestial one
  '🌌', // 50 - cosmic overlord / final
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
  'Goblin King',
  'Bone Fiend',
  'Phantom',
  'Revenant',
  'Vampire Lord',
  'Night Terror',
  'Dire Wolf',
  'Widow Fiend',
  'Kraken Spawn',
  'Leviathan',
  'Juggernaut',
  'Behemoth',
  'Colossus',
  'Tusked Titan',
  'Thunder Beast',
  'Ape King',
  'Stone Golem',
  'Mythic Steed',
  'Frost Wraith',
  'Storm Spirit',
  'Tempest Fiend',
  'Magma Titan',
  'Abyss Caller',
  'Star Being',
  'Void Invader',
  'Comet Crusher',
  'World Eater',
  'Star Devourer',
  'Celestial One',
  'Cosmic Overlord',
];

/// Emoji for a 1-based [stage] value (clamped to the valid range).
String emojiForStage(int stage) => stageEmojis[stage.clamp(1, kMaxStage) - 1];

/// Flavour name for a 1-based [stage] value (clamped to the valid range).
String nameForStage(int stage) => stageNames[stage.clamp(1, kMaxStage) - 1];
