import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';

/// 통계 탭: 주간 데이터와 인사이트 표시.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  WeeklyStats? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: RefreshIndicator(onRefresh: _loadStats, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_stats == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [Text('통계를 불러오는 중입니다. 잠시 후 다시 시도해 주세요.')],
      );
    }
    final stats = _stats!;
    final percentValue = stats.completionRate <= 1 ? stats.completionRate * 100 : stats.completionRate;
    final percentText = '${NumberFormat('##0.0').format(percentValue)}%';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('주간 완료율', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(percentText, style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('연속 달성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('${stats.streak}일', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('성공률 높은 시간대', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (stats.bestSlots.isEmpty)
                  const Text('아직 분석할 데이터가 부족합니다.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stats.bestSlots.map((slot) => Chip(label: Text(slot))).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildStringListCard('인사이트', stats.insights),
        const SizedBox(height: 16),
        _buildStringListCard('팁', stats.tips),
      ],
    );
  }

  Card _buildStringListCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('관련 내용이 없습니다.')
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $item'),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      final stats = await api.fetchWeeklyStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(ApiException error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  }
}
