class Neighborhood {
  final String name;
  final String? alias;

  const Neighborhood(this.name, [this.alias]);

  String get displayName => alias != null ? '$name ($alias)' : name;
}

const neighborhoods = [
  Neighborhood('מרכז העיר', 'המע"ר'),
  Neighborhood('הפרחים', 'מירומי'),
  Neighborhood('מורשת'),
  Neighborhood('נופים'),
  Neighborhood('מוריה', 'בוכמן דרום'),
  Neighborhood('הנחלים', 'ספדיה'),
  Neighborhood('המגינים', 'השמשוני דרום'),
  Neighborhood('אבני חן', 'קייזר'),
  Neighborhood('השבטים', 'בוכמן צפון'),
  Neighborhood('הכרמים', 'ציפור'),
  Neighborhood('משואה', 'גבעת C'),
  Neighborhood('הנביאים'),
  Neighborhood('גבעת שר'),
  Neighborhood('מכבים רעות'),
];
