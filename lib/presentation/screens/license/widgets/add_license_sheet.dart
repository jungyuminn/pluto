import 'package:flutter/material.dart';
import 'package:pluto/domain/entities/license.dart';
import 'package:pluto/presentation/screens/license/widgets/add_license_form.dart';

Future<bool> showAddLicenseSheet(
  BuildContext context, {
  License? license,
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
    builder: (context) => AddLicenseSheet(license: license),
  );
  return saved == true;
}

class AddLicenseSheet extends StatelessWidget {
  const AddLicenseSheet({super.key, this.license});

  final License? license;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        width: double.infinity,
        child: AddLicenseForm(initial: license),
      ),
    );
  }
}
