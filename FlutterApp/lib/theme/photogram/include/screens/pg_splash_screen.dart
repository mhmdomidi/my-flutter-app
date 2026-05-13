import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photogram/core/helpers/extensions.dart';

import 'package:photogram/import/bloc.dart';
import 'package:photogram/import/core.dart';
import 'package:photogram/import/interface.dart';

class PgSplashScreen extends SplashScreen {
  const PgSplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AuthBloc.of(context).pushEvent(AuthEventLoginFromLocalRepo(context));
    ThemeBloc.of(context).pushEvent(ThemeEventSetFromLocalRepo(context));

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            logoContainer(),
            companyLogoContainer(),
          ],
        ),
      ),
    );
  }

  Widget logoContainer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          AppIcons.logo,
          height: 80,
          colorFilter: ThemeBloc.colorScheme.onBackground.toColorFilter,
        )
      ],
    );
  }

  Widget companyLogoContainer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          ThemeBloc.getThemeMode == AppThemeMode.dark ? AppImages.logoCompanyOnDark : AppImages.logoCompanyOnLight,
          width: 100,
        ),
      ],
    );
  }
}
