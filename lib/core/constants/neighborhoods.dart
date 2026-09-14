class Neighborhood {
  final String name;
  final String? alias;

  const Neighborhood(this.name, [this.alias]);

  String get displayName => alias != null ? '$name ($alias)' : name;
}

const neighborhoods = [
  Neighborhood('Modiin Center'),
  Neighborhood('HaPrachim', 'Miromi'),
  Neighborhood('Moreshet'),
  Neighborhood('Nofim'),
  Neighborhood('Moriah', 'Buchman South'),
  Neighborhood('HaNechalim', 'Sfadia'),
  Neighborhood('HaMaginim'),
  Neighborhood('Avnei Chen', 'Kaiser'),
  Neighborhood('HaShvatim', 'Buchman North'),
  Neighborhood('HaKramim', 'Tzipor'),
  Neighborhood('Masuah', 'Givat C'),
  Neighborhood('HaNeviim'),
  Neighborhood('Givat Sar'),
  Neighborhood('Maccabim Reut'),
];
