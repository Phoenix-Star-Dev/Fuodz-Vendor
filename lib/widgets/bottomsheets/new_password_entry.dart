import 'package:flutter/material.dart';
import 'package:fuodz/constants/app_colors.dart';
import 'package:fuodz/extensions/context.dart';
import 'package:fuodz/services/validator.service.dart';
import 'package:fuodz/view_models/forgot_password.view_model.dart';
import 'package:fuodz/widgets/base.page.dart';
import 'package:fuodz/widgets/buttons/custom_button.dart';
import 'package:fuodz/widgets/buttons/custom_leading.dart';
import 'package:fuodz/widgets/custom_text_form_field.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

class NewPasswordEntry extends StatefulWidget {
  const NewPasswordEntry({
    required this.onSubmit,
    required this.vm,
    Key? key,
  }) : super(key: key);

  final Function(String) onSubmit;
  final ForgotPasswordViewModel vm;

  @override
  _NewPasswordEntryState createState() => _NewPasswordEntryState();
}

class _NewPasswordEntryState extends State<NewPasswordEntry> {
  final resetFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    //

    return BasePage(
      showAppBar: true,
      showLeadingAction: true,
      appBarItemColor: AppColor.primaryColor,
      title: "New Password".tr(),
      elevation: 0,
      leading: CustomLeading().onInkTap(() {
        context.pop();
      }),
      child: Form(
        key: resetFormKey,
        child: VStack(
          [
            //
            // "New Password".tr().text.bold.xl2.makeCentered(),
            "Please enter account new password".tr().text.makeCentered(),
            //pin code
            CustomTextFormField(
              labelText: "New Password".tr(),
              textEditingController: widget.vm.passwordTEC,
              validator: FormValidator.validatePassword,
              obscureText: true,
            ).py12(),

            //submit
            CustomButton(
              title: "Reset Password".tr(),
              loading: widget.vm.isBusy,
              onPressed: () {
                if (resetFormKey.currentState!.validate()) {
                  widget.onSubmit(widget.vm.passwordTEC.text);
                }
              },
            ).h(Vx.dp48),
          ],
        ).p20(),
      ),
    );
  }
}
