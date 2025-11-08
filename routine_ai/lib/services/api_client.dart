import 'package:dio/dio.dart';

import '../constants.dart';
import '../models/routine_item.dart';

const _networkErrorMessage = '서버 응답이 없습니다.';
const _formatErrorMessage = '데이터 형식 오류';

/// API 호출 중 발생한 예외 표현.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException($message)';
}

/// 펫 상태 데이터 모델.
class PetState {
  PetState({required this.level, required this.xp, required this.nextLevelThreshold});

  final int level;
  final int xp;
  final int nextLevelThreshold;

  factory PetState.fromJson(Map<String, dynamic> json) {
    final level = json['level'];
    final xp = json['xp'];
    final next = json['next_level_threshold'] ?? json['nextLevelThreshold'];
    if (level is int && xp is int && next is int) {
      return PetState(level: level, xp: xp, nextLevelThreshold: next);
    }
    throw const FormatException('Invalid pet state payload');
  }
}

/// 추천 루틴 카드 모델.
class RoutinePlan {
  RoutinePlan({
    required this.title,
    required this.days,
    required this.time,
    required this.durationMinutes,
    required this.difficulty,
    required this.reason,
  });

  final String title;
  final List<String> days;
  final String time;
  final int durationMinutes;
  final String difficulty;
  final String reason;

  factory RoutinePlan.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final days = json['days'];
    final time = json['time'];
    final duration = json['duration_min'];
    final difficulty = json['difficulty'];
    final reason = json['reason'];

    if (title is String && time is String && duration is num && difficulty is String && reason is String) {
      final dayList = days is List ? days.map((e) => e.toString()).toList() : <String>[];
      return RoutinePlan(
        title: title,
        days: dayList,
        time: time,
        durationMinutes: duration.toInt(),
        difficulty: difficulty,
        reason: reason,
      );
    }
    throw const FormatException('Invalid plan payload');
  }
}

/// 백엔드 루틴 정보.
class RoutineRemote {
  RoutineRemote({
    required this.id,
    required this.userId,
    required this.title,
    required this.time,
    required this.days,
    required this.difficulty,
    required this.active,
    required this.iconKey,
  });

  final int id;
  final int userId;
  final String title;
  final String time;
  final List<String> days;
  final String difficulty;
  final bool active;
  final String iconKey;

  factory RoutineRemote.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['user_id'] ?? json['userId'];
    final title = json['title'];
    final time = json['time'];
    final daysRaw = json['days'];
    final difficulty = (json['difficulty'] ?? 'mid').toString();
    final activeRaw = json['active'];
    final iconKey = json['icon_key'] ?? json['iconKey'] ?? 'yoga';
    if (id is int && userId is int && title is String && time is String && iconKey is String) {
      final days = daysRaw is List
          ? daysRaw.map((e) => e.toString()).toList()
          : <String>[];
      final isActive = activeRaw is bool
          ? activeRaw
          : activeRaw is num
              ? activeRaw != 0
              : true;
      return RoutineRemote(
        id: id,
        userId: userId,
        title: title,
        time: time,
        days: days,
        difficulty: difficulty,
        active: isActive,
        iconKey: iconKey,
      );
    }
    throw const FormatException('Invalid routine payload');
  }
}

/// 주간 통계 응답 모델.
class WeeklyStats {
  WeeklyStats({
    required this.completionRate,
    required this.streak,
    required this.bestSlots,
    required this.insights,
    required this.tips,
  });

  final double completionRate;
  final int streak;
  final List<String> bestSlots;
  final List<String> insights;
  final List<String> tips;

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    final rate = json['completion_rate'];
    final streak = json['streak'];
    final bestSlots = json['best_slots'];
    final insights = json['insights'];
    final tips = json['tips'];

    if (rate is num && streak is int) {
      final slotList = bestSlots is List ? bestSlots.map((e) => e.toString()).toList() : <String>[];
      final insightList = insights is List ? insights.map((e) => e.toString()).toList() : <String>[];
      final tipList = tips is List ? tips.map((e) => e.toString()).toList() : <String>[];
      return WeeklyStats(
        completionRate: rate.toDouble(),
        streak: streak,
        bestSlots: slotList,
        insights: insightList,
        tips: tipList,
      );
    }
    throw const FormatException('Invalid stats payload');
  }
}

/// 루틴 완료 보고 결과 모델.
class RoutineCompletionResult {
  RoutineCompletionResult({required this.petState, required this.streak, required this.coachHint});

  final PetState petState;
  final int? streak;
  final String? coachHint;

  factory RoutineCompletionResult.fromJson(Map<String, dynamic> json) {
    final pet = json['pet_state'];
    final streak = json['streak'];
    final hint = json['coach_hint'];
    if (pet is Map<String, dynamic>) {
      return RoutineCompletionResult(
        petState: PetState.fromJson(pet),
        streak: streak is int ? streak : null,
        coachHint: hint is String ? hint : null,
      );
    }
    throw const FormatException('Invalid completion payload');
  }
}

/// FastAPI 백엔드 호출을 담당하는 클라이언트.
class ApiClient {
  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: resolvedApiBase,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: const {'Content-Type': 'application/json'},
          ),
        );

  final Dio _dio;

  Future<String?> sendCoachMessage(String message) {
    return _guard(() async {
      final response = await _dio.post(
        '/api/coach/chat',
        data: {
          'user_id': 1,
          'message': message,
          'context_flags': {
            'include_calendar': true,
            'include_stats': true,
          },
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final reply = data['reply'];
        if (reply is String) {
          return reply;
        }
      }
      throw const FormatException('Invalid chat payload');
    });
  }

  Future<PetState> fetchPetState() {
    return _guard(() async {
      final response = await _dio.get('/api/pet/state', queryParameters: {'user_id': 1});
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PetState.fromJson(data);
      }
      throw const FormatException('Invalid pet state response');
    });
  }

  Future<RoutineRecommendation> fetchAiRecommend() async {
    final plans = await generateRoutineRecommendations(
      goals: const ['집중'],
      slots: const ['morning'],
    );
    final plan = plans.isNotEmpty
        ? plans.first
        : RoutinePlan(
            title: '아침 스트레칭',
            days: const ['월', '수', '금'],
            time: '07:30',
            durationMinutes: 20,
            difficulty: 'easy',
            reason: '하루를 상쾌하게 시작할 수 있도록 몸을 깨워줘요.',
          );
    return RoutineRecommendation(
      title: plan.title,
      iconKey: _iconKeyForPlan(plan),
      time: plan.time,
      days: plan.days,
    );
  }

  Future<List<RoutinePlan>> generateRoutineRecommendations({
    required List<String> goals,
    required List<String> slots,
  }) {
    return _guard(() async {
      final response = await _dio.post(
        '/api/recommend/generate',
        data: {
          'user_id': 1,
          'goals': goals,
          'prefer_slots': slots,
          'calendar': <dynamic>[],
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final plans = data['plans'];
        if (plans is List) {
          return plans
              .whereType<Map<String, dynamic>>()
              .map(RoutinePlan.fromJson)
              .toList();
        }
        throw const FormatException('Invalid plans array');
      }
      throw const FormatException('Invalid recommendation response');
    });
  }

  Future<WeeklyStats> fetchWeeklyStats() {
    return _guard(() async {
      final response = await _dio.get('/api/stats/weekly', queryParameters: {'user_id': 1});
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return WeeklyStats.fromJson(data);
      }
      throw const FormatException('Invalid stats response');
    });
  }

  Future<RoutineCompletionResult> reportRoutineCompletion({
    required int routineId,
    required String status,
    required DateTime startedAt,
    required DateTime endedAt,
    String? note,
  }) {
    return _guard(() async {
      final response = await _dio.post(
        '/api/routine/complete',
        data: {
          'user_id': 1,
          'routine_id': routineId,
          'status': status,
          'started_at': startedAt.toIso8601String(),
          'ended_at': endedAt.toIso8601String(),
          'note': note,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return RoutineCompletionResult.fromJson(data);
      }
      throw const FormatException('Invalid completion response');
    });
  }

  Future<List<RoutineRemote>> fetchUserRoutines() {
    return _guard(() async {
      final response = await _dio.get('/api/routine', queryParameters: {'user_id': 1});
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(RoutineRemote.fromJson)
            .toList();
      }
      throw const FormatException('Invalid routine list');
    });
  }

  Future<RoutineRemote> createRoutine({
    required String title,
    required String time,
    required List<String> days,
    required String difficulty,
    required bool active,
    required String iconKey,
  }) {
    return _guard(() async {
      final response = await _dio.post(
        '/api/routine',
        data: {
          'user_id': 1,
          'title': title,
          'time': time,
          'days': days,
          'difficulty': difficulty,
          'active': active,
          'icon_key': iconKey,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return RoutineRemote.fromJson(data);
      }
      throw const FormatException('Invalid routine payload');
    });
  }

  Future<RoutineRemote> updateRoutine({
    required int routineId,
    required String title,
    required String time,
    required List<String> days,
    required String difficulty,
    required bool active,
    required String iconKey,
  }) {
    return _guard(() async {
      final response = await _dio.put(
        '/api/routine/$routineId',
        data: {
          'title': title,
          'time': time,
          'days': days,
          'difficulty': difficulty,
          'active': active,
          'icon_key': iconKey,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return RoutineRemote.fromJson(data);
      }
      throw const FormatException('Invalid routine payload');
    });
  }

  Future<void> deleteRoutine({required int routineId}) {
    return _guard<void>(() async {
      await _dio.delete('/api/routine/$routineId');
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException {
      throw const ApiException(_networkErrorMessage);
    } on FormatException {
      throw const ApiException(_formatErrorMessage);
    } catch (_) {
      throw const ApiException(_networkErrorMessage);
    }
  }

  String _iconKeyForPlan(RoutinePlan plan) {
    final title = plan.title.toLowerCase();
    if (title.contains('수면') || title.contains('휴식')) {
      return 'sleep';
    }
    if (title.contains('독서') || title.contains('공부')) {
      return 'book';
    }
    if (title.contains('청소') || title.contains('정리')) {
      return 'clean';
    }
    switch (plan.difficulty) {
      case 'hard':
        return 'run';
      case 'mid':
        return 'task';
      default:
        return 'yoga';
    }
  }
}
