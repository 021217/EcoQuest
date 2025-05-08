class StepConversion {
  static const int stepsPerPoint = 10;
  static const int pointsPerDrop = 10;
  static const int challengeThreshold = 2000;
  static const int challengeBonus = 100;

  static StepResult convertSteps(int stepCount) {
    int points = stepCount ~/ stepsPerPoint;
    int bonusPoints = (stepCount >= challengeThreshold) ? challengeBonus : 0;
    int totalPoints = points + bonusPoints;
    int drops = totalPoints ~/ pointsPerDrop;

    return StepResult(
      steps: stepCount,
      points: points,
      bonusPoints: bonusPoints,
      drops: drops,
    );
  }
}

class StepResult {
  final int steps;
  final int points;
  final int bonusPoints;
  final int drops;

  StepResult({
    required this.steps,
    required this.points,
    required this.bonusPoints,
    required this.drops,
  });

  int get totalPoints => points + bonusPoints;
}
