/// Animal emoji used as user "profile pictures".
///
/// Consistent with the app's emoji-only asset decision (see
/// `stages.dart`), a profile picture is just an emoji — no image files.
library;

/// Selectable animal icons for a user profile. The first entry is the default
/// assigned to the migrated / first-run profile.
const List<String> animalIcons = <String>[
  '🦊', // fox
  '🐶', // dog
  '🐱', // cat
  '🐼', // panda
  '🐨', // koala
  '🦁', // lion
  '🐯', // tiger
  '🐸', // frog
  '🐵', // monkey
  '🐧', // penguin
  '🦉', // owl
  '🦄', // unicorn
  '🐙', // octopus
  '🐢', // turtle
  '🐝', // bee
  '🦋', // butterfly
  '🐬', // dolphin
  '🦖', // t-rex
  '🐰', // rabbit
  '🐺', // wolf
];

/// The default animal for a brand-new / migrated profile.
const String defaultAnimal = '🦊';
