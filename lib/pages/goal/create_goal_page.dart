import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/goal_provider.dart';
import 'goal_form_page.dart';

class CreateGoalPage extends StatelessWidget {
  const CreateGoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GoalFormPage(
      pageTitle: '新建旅程',
      introTitle: '定义这段旅程',
      introSubtitle: '先写下你想推进什么，再决定它会以怎样的节奏展开。',
      submitLabel: '创建旅程',
      successMessage: '新旅程已创建',
      errorMessage: '创建失败，请稍后重试',
      onSubmit: (data) async {
        final goal = await context.read<GoalProvider>().createGoal(
          title: data.title,
          category: data.category,
          reason: data.reason,
          vision: data.vision,
          deadline: data.deadline,
          steps: data.steps,
          isPublic: data.isPublic,
        );
        return goal != null;
      },
    );
  }
}
