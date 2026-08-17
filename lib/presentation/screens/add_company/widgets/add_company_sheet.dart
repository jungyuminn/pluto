import 'package:flutter/material.dart';
import 'package:job_planner/domain/entities/job_application.dart';
import 'package:job_planner/presentation/screens/add_company/widgets/add_company_form.dart';

Future<bool> showAddCompanySheet(
  BuildContext context, {
  JobApplication? application,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x33000000),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => AddCompanySheet(application: application),
  );
  return saved == true;
}

class AddCompanySheet extends StatelessWidget {
  const AddCompanySheet({super.key, this.application});

  final JobApplication? application;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        width: double.infinity,
        child: AddCompanyForm(initial: application),
      ),
    );
  }
}
