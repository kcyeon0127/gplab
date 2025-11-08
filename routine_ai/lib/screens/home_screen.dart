import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      appState.applyPetState(PetState(level: 1, xp: 0, nextLevelThreshold: 100));
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
    final selectedIndex =
    weekly.isEmpty ? 0 : appState.selectedDayIndex.clamp(0, weekly.length - 1);

    final WeeklyDayStatus? selectedStatus =
    weekly.isEmpty ? null : weekly[selectedIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PetStatusCard(
                  petState: appState.petState,
                  isLoading: appState.isLoadingPet,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '11월 달력',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40),
                      child: WeeklyRingBar(
                        weekly: weekly,
                        selectedIndex: selectedIndex,
                        onSelect: (index) => context.read<AppState>().selectDay(index),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TriangleToggleButton(
                    isOpen: appState.isWeeklyPanelOpen,
                    onTap: () => context.read<AppState>().toggleWeeklyPanel(),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: CoachSection(
                    onGo: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecommendScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isFetchingRecommend ? null : _openAiRecommendRoutine,
                    icon: _isFetchingRecommend
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isFetchingRecommend ? '불러오는 중...' : 'AI 추천으로 추가'),
                  ),
                ),
                const SizedBox(height: 24),
                // 오늘(또는 선택 요일) 루틴 리스트
                _buildTodaySection(
                  context,
                  selectedStatus,
                  appState.selectedDayRoutines,
                ),

                const SizedBox(height: 24),

                // AI 루틴 추천 이동 카드
                _buildRecommendCard(context),
              ],
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
      ) {
    final label = status == null ? '오늘의 루틴' : '${status.weekdayLabel}요일 루틴';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        // 루틴이 없을 때 안내
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
            child: const Text('오늘은 예정된 루틴이 없습니다.'),
          )
        else
        // 루틴 카드 리스트
          Column(
            children: routines.map((routine) {
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
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(routine.icon, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 16),

                    // 제목/시간
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routine.title,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text('시간: ${routine.time}',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),

                    // (임시) 완료 토글 자리
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('루틴 완료 토글은 추후 연결 예정입니다.'),
                          ),
                        );
                      },
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecommendScreen()),
      ),
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
                    Text('AI 루틴 추천 받기',
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          builder: (_) => CreateRoutineScreen(initialRoutine: recommendation),
        ),
      );
    } on ApiException catch (error) {
      _showError(error);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('추천을 불러오지 못했어요: $error')));
    } finally {
      if (mounted) {
        setState(() => _isFetchingRecommend = false);
      }
    }
  }

  /// API 예외를 사용자 메시지로 변환하여 스낵바로 노출
  void _showError(ApiException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  }

}
