/// A user profile: a name and a chosen animal emoji ("profile picture").
///
/// Each profile owns its own monster progress, persisted separately by
/// [MonsterState] under keys namespaced by [id]. The profile itself only
/// carries identity + display fields; progress lives in SharedPreferences.
class Profile {
  Profile({required this.id, required this.name, required this.animal});

  /// Stable unique id (also used to namespace this profile's progress keys).
  final String id;

  /// Display name entered by the user.
  String name;

  /// Animal emoji shown as the profile picture.
  String animal;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'animal': animal,
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    name: json['name'] as String,
    animal: json['animal'] as String,
  );
}
