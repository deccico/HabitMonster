/// Static data for the monster evolution lines.
///
/// Per the user's decision, monsters are represented by emoji rather than
/// bundled image files. Each line is a single, coherent creature arc — the
/// *same* creature growing up rather than swapping to unrelated icons — going
/// cute -> epic over [kMaxStage] stages.
///
/// Every line starts from the identical '🥚 Mystery Egg' and the line itself
/// is picked at random for every new egg (new profile, prestige wrap, reset),
/// so which creature is inside stays a surprise until it hatches. Emoji only
/// ships a couple of literal glyphs per creature, so the final "epic" stages
/// show the creature mastering an element — the flavour names keep its
/// identity ("… Dragon", "… Rex", …).
library;

/// Total number of evolution stages in every line.
const int kMaxStage = 15;

/// One coherent creature arc: parallel emoji/name lists, one per stage.
class EvolutionLine {
  const EvolutionLine({
    required this.name,
    required this.emojis,
    required this.names,
  });

  /// Internal name of the line (analytics/debugging; not shown to kids).
  final String name;

  /// Emoji per stage. Index `i` corresponds to stage `i + 1`.
  final List<String> emojis;

  /// Short flavour name per stage (index `i` == stage `i + 1`).
  final List<String> names;
}

/// All available lines. A new egg rolls a random index into this list.
const List<EvolutionLine> kEvolutionLines = <EvolutionLine>[
  EvolutionLine(
    name: 'dragon',
    emojis: <String>[
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
    ],
    names: <String>[
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
    ],
  ),
  EvolutionLine(
    name: 'phoenix',
    emojis: <String>[
      '🥚', // 1  - egg
      '🐣', // 2  - hatchling emerging
      '🐤', // 3  - chick
      '🐥', // 4  - fledgling
      '🐦', // 5  - songbird
      '🕊️', // 6  - skydancer
      '🦆', // 7  - wavewing
      '🦉', // 8  - night owl
      '🦅', // 9  - sky hunter
      '🦚', // 10 - royal peacock
      '🦜', // 11 - flame parrot
      '🔥', // 12 - emberwing (feathers ignite)
      '🐦‍🔥', // 13 - phoenix
      '☀️', // 14 - solar phoenix
      '🌟', // 15 - celestial firebird / final
    ],
    names: <String>[
      'Mystery Egg',
      'Hatchling',
      'Chick',
      'Fledgling',
      'Songbird',
      'Skydancer',
      'Wavewing',
      'Night Owl',
      'Sky Hunter',
      'Royal Peacock',
      'Flame Parrot',
      'Emberwing',
      'Phoenix',
      'Solar Phoenix',
      'Celestial Firebird',
    ],
  ),
  EvolutionLine(
    name: 'leviathan',
    emojis: <String>[
      '🥚', // 1  - egg
      '🪱', // 2  - wriggler
      '🐟', // 3  - fry
      '🐠', // 4  - reef darter
      '🐡', // 5  - spikefin
      '🦀', // 6  - clawling
      '🐢', // 7  - shellback
      '🐍', // 8  - sea serpent
      '🦈', // 9  - deep hunter
      '🐙', // 10 - octoterror
      '🦑', // 11 - kraken spawn
      '🐊', // 12 - tide ripper
      '🐋', // 13 - leviathan
      '🌊', // 14 - tidal titan
      '🌌', // 15 - abyss sovereign / final
    ],
    names: <String>[
      'Mystery Egg',
      'Wriggler',
      'Fry',
      'Reef Darter',
      'Spikefin',
      'Clawling',
      'Shellback',
      'Sea Serpent',
      'Deep Hunter',
      'Octoterror',
      'Kraken Spawn',
      'Tide Ripper',
      'Leviathan',
      'Tidal Titan',
      'Abyss Sovereign',
    ],
  ),
  EvolutionLine(
    name: 'dino',
    emojis: <String>[
      '🥚', // 1  - egg
      '🐣', // 2  - hatchling emerging
      '🦎', // 3  - lizardling
      '🐢', // 4  - armored youngling
      '🐊', // 5  - riverjaw
      '🦕', // 6  - gentle longneck
      '🦖', // 7  - young tyrant
      '🌿', // 8  - jungle stomper
      '⛰️', // 9  - mountain crusher
      '🌪️', // 10 - cyclone rex
      '⚡', // 11 - thunder lizard
      '🌋', // 12 - magma rex
      '❄️', // 13 - ice age rex
      '☄️', // 14 - comet king
      '🌌', // 15 - cosmic rex / final
    ],
    names: <String>[
      'Mystery Egg',
      'Hatchling',
      'Lizardling',
      'Armored Youngling',
      'Riverjaw',
      'Gentle Longneck',
      'Young Tyrant',
      'Jungle Stomper',
      'Mountain Crusher',
      'Cyclone Rex',
      'Thunder Lizard',
      'Magma Rex',
      'Ice Age Rex',
      'Comet King',
      'Cosmic Rex',
    ],
  ),
  EvolutionLine(
    name: 'alien',
    emojis: <String>[
      '🥚', // 1  - egg
      '🦠', // 2  - star microbe
      '🪱', // 3  - space wriggler
      '🐛', // 4  - larvoid
      '🐙', // 5  - tentacloid
      '🦑', // 6  - void squid
      '👾', // 7  - pixel invader
      '👽', // 8  - grey visitor
      '🛸', // 9  - saucer pilot
      '🌑', // 10 - dark moon lurker
      '☄️', // 11 - comet rider
      '🪐', // 12 - ring lord
      '💫', // 13 - star weaver
      '🌟', // 14 - supernova
      '🌌', // 15 - cosmic overmind / final
    ],
    names: <String>[
      'Mystery Egg',
      'Star Microbe',
      'Space Wriggler',
      'Larvoid',
      'Tentacloid',
      'Void Squid',
      'Pixel Invader',
      'Grey Visitor',
      'Saucer Pilot',
      'Dark Moon Lurker',
      'Comet Rider',
      'Ring Lord',
      'Star Weaver',
      'Supernova',
      'Cosmic Overmind',
    ],
  ),
];

EvolutionLine _line(int lineIndex) =>
    kEvolutionLines[lineIndex.clamp(0, kEvolutionLines.length - 1)];

/// Emoji for a 1-based [stage] value in the given line (both clamped).
String emojiForStage(int stage, int lineIndex) =>
    _line(lineIndex).emojis[stage.clamp(1, kMaxStage) - 1];

/// Flavour name for a 1-based [stage] value in the given line (both clamped).
String nameForStage(int stage, int lineIndex) =>
    _line(lineIndex).names[stage.clamp(1, kMaxStage) - 1];
