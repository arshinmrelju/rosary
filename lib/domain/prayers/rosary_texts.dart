/// Standard Catholic prayers used inside a single decade of the Rosary.
///
/// Pure Dart, no UI types. Used by the Today's Decade screen. An admin could
/// later supply custom texts via dailyContent without changing this file.
abstract final class RosaryTexts {
  static const String signOfTheCross =
      'In the name of the Father, and of the Son, and of the Holy Spirit. Amen.';

  static const String ourFather =
      'Our Father, who art in heaven, hallowed be thy name; thy kingdom come, '
      'thy will be done on earth as it is in heaven. Give us this day our daily '
      'bread; and forgive us our trespasses as we forgive those who trespass '
      'against us; and lead us not into temptation, but deliver us from evil. '
      'Amen.';

  static const String hailMary10 =
      'Told one by one as the beads are counted — ten Hail Marys while '
      'reflecting on the mystery.';

  static const String gloryBe =
      'Glory be to the Father, and to the Son, and to the Holy Spirit. As it '
      'was in the beginning, is now, and ever shall be, world without end. '
      'Amen.';

  static const String fatimaPrayer =
      'O my Jesus, forgive us our sins, save us from the fires of hell, lead '
      'all souls to heaven, especially those most in need of your mercy. '
      'Amen.';
}