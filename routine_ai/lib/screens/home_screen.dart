import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/routine_item.dart';
import '../models/weekly_day_status.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../widgets/pet_status_card.dart';
import '../widgets/coach_section.dart';
import '../widgets/right_slide_panel.dart';
import '../widgets/triangle_toggle_button.dart';
import '../widgets/weekly_ring_bar.dart';
import 'recommend_screen.dart';
import 'create_routine_screen.dart';

/// 메인 탭: 코치 챗봇, 펫 상태, 주간 패널 등을 포함한다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _didInit = false;
  bool _isFetchingRecommend = false;
  final Set<int> _completingRoutineIds = <int>{};

  static const List<_RoutineStatusOption> _statusOptions = [
    _RoutineStatusOption('done', '완료', Icons.check_circle, kSeedColor),
    _RoutineStatusOption('late', '지각', Icons.timelapse, Color(0xFF64B5F6)),
    _RoutineStatusOption(
      'partial',
      '부분',
      Icons.incomplete_circle,
      Color(0xFFFFB74D),
    ),
    _RoutineStatusOption('miss', '미완료', Icons.close_rounded, Color(0xFFF46D6D)),
  ];
  static const _RoutineStatusOption _pendingOption = _RoutineStatusOption(
    'pending',
    '대기',
    Icons.radio_button_unchecked,
    Colors.grey,
  );

  @override
  void initState() {
    super.initState();
    // 첫 빌드 이후 초기 데이터 로딩 (펫 상태/주간 개요)
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialData());
  }

  /// 최초 1회만 펫/주간 데이터를 불러온다.
  Future<void> _ensureInitialData() async {
    if (_didInit) return;
    _didInit = true;
    final appState = context.read<AppState>();

    // 펫 상태 로딩
    final error = await appState.refreshPetState();
    if (mounted && error != null) {
      _showError(error);
      appState.applyPetState(
        PetState(level: 1, xp: 0, nextLevelThreshold: 100),
      );
    }

    // 주간 개요(더미 → 추후 API 교체 예정)
    await appState.bootstrapWeeklyOverview();

    final routinesError = await appState.ensureCalendarRoutinesLoaded();
    if (mounted && routinesError != null) {
      _showError(routinesError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final weekly = appState.weeklyStatuses;

    // 선택된 요일 인덱스 보정
    final int selectedIndex = weekly.isEmpty
        ? 0
        : appState.selectedDayIndex.clamp(0, weekly.length - 1).toInt();

    final WeeklyDayStatus? selectedStatus = weekly.isEmpty
        ? null
        : weekly[selectedIndex];

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PetStatusCard(
                    petState: appState.petState,
                    isLoading: appState.isLoadingPet,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '11월',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 110,
                    child: WeeklyRingBar(
                      weekly: weekly,
                      selectedIndex: selectedIndex,
                      onSelect: (index) =>
                          context.read<AppState>().selectDay(index),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TriangleToggleButton(
                      isOpen: appState.isWeeklyPanelOpen,
                      onTap: () => context.read<AppState>().toggleWeeklyPanel(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: CoachSection(
                      onGo: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecommendScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 오늘(또는 선택 요일) 루틴 리스트
                  _buildTodaySection(
                    context,
                    selectedStatus,
                    appState.selectedDayRoutines,
                    appState,
                  ),

                  const SizedBox(height: 24),

                  // AI 루틴 추천 이동 카드
                  _buildRecommendCard(context),
                ],
              ),
            ),
          ),

          // 오른쪽 슬라이드 패널 열렸을 때 뒤 배경 탭 감지 + 반투명 처리
          if (appState.isWeeklyPanelOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => context.read<AppState>().closeWeeklyPanel(),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),

          // 오른쪽 슬라이드 패널(주간 상세)
          RightSlidePanel(
            isOpen: appState.isWeeklyPanelOpen,
            selectedStatus: selectedStatus,
            routines: appState.selectedDayRoutines,
            progressList: appState.weeklyRoutineProgress,
            onClose: () => context.read<AppState>().closeWeeklyPanel(),
          ),
        ],
      ),
    );
  }

  /// "오늘의 루틴" 섹션(또는 선택 요일 루틴) 렌더
  Widget _buildTodaySection(
    BuildContext context,
    WeeklyDayStatus? status,
    List<RoutineItem> routines,
    AppState appState,
  ) {
    final date = status?.date ?? DateTime.now();
    final label = status == null
        ? '오늘의 루틴'
        : '${date.month}월 ${date.day}일 (${status.weekdayLabel}) 루틴';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (routines.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text('등록된 루틴이 없습니다. 루틴 관리 탭에서 추가해 보세요.'),
          )
        else
          Column(
            children: routines.map((routine) {
              final statusValue = appState.routineStatusForDate(
                routine.id,
                date,
              );
              final statusOption = _optionForStatus(statusValue);
              final isUpdating = _completingRoutineIds.contains(routine.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: kSeedColor.withValues(alpha: 0.15),
                          child: Icon(routine.icon, color: kSeedColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                routine.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '시간: ${routine.time}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 40,
                          child: isUpdating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : PopupMenuButton<String>(
                                  tooltip: '루틴 상태 변경',
                                  onSelected: (value) =>
                                      _handleRoutineStatusChange(
                                        routine,
                                        value,
                                        date,
                                      ),
                                  itemBuilder: (context) => _statusOptions
                                      .map(
                                        (option) => PopupMenuItem<String>(
                                          value: option.value,
                                          child: Row(
                                            children: [
                                              Icon(
                                                option.icon,
                                                color: option.color,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(option.label),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  icon: Icon(
                                    statusOption.icon,
                                    color: statusOption.color,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (routine.days.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: routine.days
                            .map(
                              (day) => Chip(
                                label: Text(day),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusOption.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '상태: ${statusOption.label}',
                        style: TextStyle(
                          color: statusOption.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// 추천 화면으로 이동하는 카드
  Widget _buildRecommendCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RecommendScreen())),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'AI 루틴 추천 받기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('목표와 시간대를 선택해 맞춤 루틴을 받아보세요.'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAiRecommendRoutine() async {
    final api = context.read<ApiClient>();
    setState(() => _isFetchingRecommend = true);
    try {
      final recommendation = await api.fetchAiRecommend();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateRoutineScreen(
            initialRoutine: recommendation,
            initialDifficulty: recommendation.difficulty,
          ),
        ),
      );
    } on ApiException catch (error) {
      _showError(error);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('추천을 불러오지 못했어요: $error')));
    } finally {
      if (mounted) {
        setState(() => _isFetchingRecommend = false);
      }
    }
  }

  Future<void> _handleRoutineStatusChange(
    RoutineItem routine,
    String newStatus,
    DateTime date,
  ) async {
    final appState = context.read<AppState>();
    final current = appState.routineStatusForDate(routine.id, date);
    if (current == newStatus) return;

    setState(() => _completingRoutineIds.add(routine.id));
    try {
      final result = await appState.completeRoutine(
        routine: routine,
        status: newStatus,
        completedDate: date,
      );
      if (!mounted) return;
      final hint = result.coachHint?.trim();
      final message = (hint == null || hint.isEmpty) ? '루틴 상태가 저장되었습니다.' : hint;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _completingRoutineIds.remove(routine.id));
      }
    }
  }

  static _RoutineStatusOption _optionForStatus(String value) {
    return _statusOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => _pendingOption,
    );
  }

  /// API 예외를 사용자 메시지로 변환하여 스낵바로 노출
  void _showError(ApiException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _RoutineStatusOption {
  const _RoutineStatusOption(this.value, this.label, this.icon, this.color);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}
