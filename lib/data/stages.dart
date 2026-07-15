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
///
/// INVARIANT (enforced by stages_test.dart): apart from the shared stage-1
/// egg, no two lines may use the same emoji at the same stage. The random
/// roll is only *visible* if the lines diverge immediately after hatching —
/// earlier data reused 🐣/🦎/🦕/🦖 across lines, which made every fresh egg
/// look identical for the first week regardless of which line was rolled.
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
      '🦎', // 2  - tiny dragonling
      '🐍', // 3  - serpentling
      '🐊', // 4  - snapjaw saurian
      '🐲', // 5  - young dragon (horns & wings emerge)
      '🐉', // 6  - full winged dragon
      '🔥', // 7  - inferno dragon (breath awakens)
      '⚡', // 8  - storm dragon
      '🌋', // 9  - volcanic wyrm
      '🌪️', // 10 - tempest wyrm
      '⛈️', // 11 - thunder wyrm
      '☄️', // 12 - comet dragon
      '🌠', // 13 - astral dragon
      '💥', // 14 - nova dragon
      '🎆', // 15 - celestial dragon / final
    ],
    names: <String>[
      'Mystery Egg',
      'Dragonling',
      'Serpentling',
      'Snapjaw',
      'Young Dragon',
      'Winged Dragon',
      'Inferno Dragon',
      'Storm Dragon',
      'Volcanic Wyrm',
      'Tempest Wyrm',
      'Thunder Wyrm',
      'Comet Dragon',
      'Astral Dragon',
      'Nova Dragon',
      'Celestial Dragon',
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
      '🔱', // 15 - abyss sovereign / final
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
      '🐢', // 2  - armored hatchling
      '🦕', // 3  - little longneck
      '🦖', // 4  - young tyrant
      '🌿', // 5  - jungle stomper
      '⛰️', // 6  - mountain crusher
      '🌪️', // 7  - cyclone rex
      '❄️', // 8  - ice age rex
      '⚡', // 9  - thunder lizard
      '🌋', // 10 - magma rex
      '☄️', // 11 - comet king
      '💥', // 12 - meteor rex
      '🌎', // 13 - earthshaker rex
      '👑', // 14 - king rex
      '🌠', // 15 - cosmic rex / final
    ],
    names: <String>[
      'Mystery Egg',
      'Armored Hatchling',
      'Little Longneck',
      'Young Tyrant',
      'Jungle Stomper',
      'Mountain Crusher',
      'Cyclone Rex',
      'Ice Age Rex',
      'Thunder Lizard',
      'Magma Rex',
      'Comet King',
      'Meteor Rex',
      'Earthshaker Rex',
      'King Rex',
      'Cosmic Rex',
    ],
  ),
  EvolutionLine(
    name: 'alien',
    emojis: <String>[
      '🥚', // 1  - egg
      '🦠', // 2  - star microbe
      '🐛', // 3  - larvoid
      '👾', // 4  - pixel invader
      '🐙', // 5  - tentacloid
      '🦑', // 6  - void squid
      '👽', // 7  - grey visitor
      '🛸', // 8  - saucer pilot
      '🌑', // 9  - dark moon lurker
      '💫', // 10 - star weaver
      '🪐', // 11 - ring lord
      '🌟', // 12 - supernova
      '🕳️', // 13 - black hole beast
      '🌀', // 14 - galaxy spinner
      '🌌', // 15 - cosmic overmind / final
    ],
    names: <String>[
      'Mystery Egg',
      'Star Microbe',
      'Larvoid',
      'Pixel Invader',
      'Tentacloid',
      'Void Squid',
      'Grey Visitor',
      'Saucer Pilot',
      'Dark Moon Lurker',
      'Star Weaver',
      'Ring Lord',
      'Supernova',
      'Black Hole Beast',
      'Galaxy Spinner',
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
