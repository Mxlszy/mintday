import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../providers/goal_provider.dart';
import 'goal_form_page.dart';

class EditGoalPage extends StatelessWidget {
  final Goal goal;

  const EditGoalPage({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return GoalFormPage(
      pageTitle: '编辑目标',
      introTitle: '调整这段旅程',
      introSubtitle: '把新的节奏、动机和步骤更新到当前旅程里。',
      submitLabel: '保存修改',
      successMessage: '目标已更新',
      errorMessage: '保存失败，请稍后重试',
      initialGoal: goal,
      onSubmit: (data) {
        final updatedGoal = Goal(
          id: goal.id,
          title: data.title,
          category: data.category,
          reason: data.reason,
          vision: data.vision,
          deadline: data.deadline,
          steps: data.steps,
          completedSteps: _reconcileCompletedSteps(goal, data.steps),
          status: goal.status,
          createdAt: goal.createdAt,
          updatedAt: goal.updatedAt,
          isMintable: goal.isMintable,
          seasonId: goal.seasonId,
          isPublic: data.isPublic,
          reward: goal.reward,
        );

        return context.read<GoalProvider>().updateGoal(updatedGoal);
      },
    );
  }

  List<bool> _reconcileCompletedSteps(Goal goal, List<String> nextSteps) {
    final stepStatusBuckets = <String, Queue<bool>>{};

    for (var index = 0; index < goal.steps.length; index++) {
      final step = goal.steps[index].trim();
      final isDone = index < goal.completedSteps.length
          ? goal.completedSteps[index]
          : false;
      (stepStatusBuckets[step] ??= Queue<bool>()).add(isDone);
    }

    return nextSteps.map((step) {
      final queue = stepStatusBuckets[step.trim()];
      if (queue == null || queue.isEmpty) {
        return false;
      }
      return queue.removeFirst();
    }).toList();
  }
}
