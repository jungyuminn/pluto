import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_planner/app.dart';
import 'package:job_planner/core/constants/app_strings.dart';
import 'package:job_planner/data/repositories/job_application_memory_repository.dart';
import 'package:job_planner/domain/usecases/add_job_application.dart';
import 'package:job_planner/domain/usecases/delete_job_application.dart';
import 'package:job_planner/domain/usecases/get_job_applications.dart';
import 'package:job_planner/domain/usecases/reorder_job_applications.dart';
import 'package:job_planner/domain/usecases/update_job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/save_company_button.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_bottom_nav.dart';
import 'package:job_planner/presentation/screens/shell/widgets/pill_nav_item.dart';

JobPlannerApp _app() {
  final repository = JobApplicationMemoryRepository();
  return JobPlannerApp(
    getJobApplications: GetJobApplications(repository),
    addJobApplication: AddJobApplication(repository),
    updateJobApplication: UpdateJobApplication(repository),
    deleteJobApplication: DeleteJobApplication(repository),
    reorderJobApplications: ReorderJobApplications(repository),
  );
}

Future<void> _pickCompanyCategory(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.categoryAction));
  await tester.pumpAndSettle();
  await tester.tap(find.text('공기업'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('앱 시작 시 캘린더 탭과 하단 네비가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(PillBottomNav), findsOneWidget);
    expect(find.text(AppStrings.addCompany), findsNothing);
    expect(find.text('일'), findsOneWidget);
    expect(find.text('토'), findsOneWidget);
  });

  testWidgets('취업관리 화면에 기업 추가 버튼이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PillNavItem).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.addCompany), findsOneWidget);
  });

  testWidgets('기업을 저장하면 취업관리에 카드가 생긴다', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PillNavItem).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addCompany));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '삼성전자');
    await tester.enterText(find.byType(TextField).at(1), '소프트웨어 개발');
    await _pickCompanyCategory(tester);
    await tester.tap(find.byType(SaveCompanyButton));
    await tester.pumpAndSettle();

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text(' (소프트웨어 개발)'), findsOneWidget);
    expect(find.text(AppStrings.addCompany), findsOneWidget);
  });

  testWidgets('카드를 눌러 내용을 수정할 수 있다', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PillNavItem).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addCompany));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '삼성전자');
    await _pickCompanyCategory(tester);
    await tester.tap(find.byType(SaveCompanyButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('삼성전자'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '네이버');
    await tester.tap(find.byType(SaveCompanyButton));
    await tester.pumpAndSettle();

    expect(find.text('네이버'), findsOneWidget);
    expect(find.text('삼성전자'), findsNothing);
  });

  testWidgets('카드를 길게 눌러 삭제할 수 있다', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PillNavItem).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.addCompany));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '삼성전자');
    await _pickCompanyCategory(tester);
    await tester.tap(find.byType(SaveCompanyButton));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('삼성전자'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.deleteTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.delete));
    await tester.pumpAndSettle();

    expect(find.text('삼성전자'), findsNothing);
  });
}
