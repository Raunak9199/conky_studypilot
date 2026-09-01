import '../models/study_day.dart';

abstract class StorageService {
  /// Loads the 30-day study plan. 
  /// In V1, this will return the static data. In V2, it might fetch from a JSON file or Network.
  Future<List<StudyDay>> loadStudyPlan();

  /// Persists the start date of the study plan.
  Future<void> savePlanStartDate(DateTime date);

  /// Retrieves the start date of the study plan. Returns null if not started.
  Future<DateTime?> getPlanStartDate();
}
