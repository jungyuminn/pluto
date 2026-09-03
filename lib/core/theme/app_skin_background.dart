import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:job_planner/app_scope.dart';
import 'package:job_planner/core/constants/app_icons.dart';
import 'package:job_planner/core/layout/pc_layout.dart';
import 'package:job_planner/core/theme/app_colors.dart';
import 'package:job_planner/core/utils/local_file.dart';
import 'package:job_planner/data/datasources/theme_preference.dart';
import 'package:job_planner/presentation/widgets/local_file_image.dart';

class AppSkinAssets {
  AppSkinAssets._();

  static const petal90Light =
      'assets/themes/blossom/petal_single_light_90deg.png';
  static const petal180Light =
      'assets/themes/blossom/petal_single_light_180deg.png';
  static const petal270Light =
      'assets/themes/blossom/petal_single_light_270deg.png';
  static const petal90Dark =
      'assets/themes/blossom/petal_single_dark_90deg.png';
  static const petal180Dark =
      'assets/themes/blossom/petal_single_dark_180deg.png';
  static const petal270Dark =
      'assets/themes/blossom/petal_single_dark_270deg.png';
  static const hillsLight =
      'assets/themes/blossom/blossom_bottom_hills_light.png';
  static const hillsDark =
      'assets/themes/blossom/blossom_bottom_hills_dark.png';

  static const cloverDecorationLight =
      'assets/themes/clover/clover_decoration_light.png';
  static const cloverDecorationDark =
      'assets/themes/clover/clover_decoration_dark.png';
  static const cloverBottomLight =
      'assets/themes/clover/clover_bottom_light.png';
  static const cloverBottomDark =
      'assets/themes/clover/clover_bottom_dark.png';

  static const fluffyBearFaceLight =
      'assets/themes/fluffy_bear/bear_face_decoration_light.png';
  static const fluffyBearFaceDark =
      'assets/themes/fluffy_bear/bear_face_decoration_dark.png';
  static const fluffyBearBottomLight =
      'assets/themes/fluffy_bear/bear_face_bottom_light.png';
  static const fluffyBearBottomDark =
      'assets/themes/fluffy_bear/bear_face_bottom_dark.png';

  static const fluffyRabbitFaceLight =
      'assets/themes/fluffy_rabbit/bunny_face_decoration_light.png';
  static const fluffyRabbitFaceDark =
      'assets/themes/fluffy_rabbit/bunny_face_decoration_dark.png';
  static const fluffyRabbitBottomLight =
      'assets/themes/fluffy_rabbit/bunny_face_bottom_light.png';
  static const fluffyRabbitBottomDark =
      'assets/themes/fluffy_rabbit/bunny_face_bottom_dark.png';

  static const pinkHeartFaceLight =
      'assets/themes/pink_heart/heart_decoration_light.png';
  static const pinkHeartFaceDark =
      'assets/themes/pink_heart/heart_decoration_dark.png';
  static const pinkHeartBottomLight =
      'assets/themes/pink_heart/heart_bottom_light.png';
  static const pinkHeartBottomDark =
      'assets/themes/pink_heart/heart_bottom_dark.png';

  static const sunLight = 'assets/themes/summer_beach/summer_sun_light.png';
  static const sunDark = 'assets/themes/summer_beach/summer_sun_dark.png';
  static const duckLight = 'assets/themes/summer_beach/duck_ring_light.png';
  static const duckDark = 'assets/themes/summer_beach/duck_ring_dark.png';
  static const shellLight = 'assets/themes/summer_beach/shell_star_light.png';
  static const shellDark = 'assets/themes/summer_beach/shell_star_dark.png';
  static const waveLight =
      'assets/themes/summer_beach/sea_wave_bottom_light.png';
  static const waveDark =
      'assets/themes/summer_beach/sea_wave_bottom_dark.png';

  static const snowmanLight = 'assets/themes/snowy_winter/snowman_light.png';
  static const snowmanDark = 'assets/themes/snowy_winter/snowman_dark.png';
  static const snowflakeLight =
      'assets/themes/snowy_winter/snowflake_light.png';
  static const snowflakeDark = 'assets/themes/snowy_winter/snowflake_dark.png';
  static const snowCloudLight =
      'assets/themes/snowy_winter/snow_cloud_light.png';
  static const snowCloudDark = 'assets/themes/snowy_winter/snow_cloud_dark.png';
  static const snowGroundLight =
      'assets/themes/snowy_winter/snow_ground_light.png';
  static const snowGroundDark =
      'assets/themes/snowy_winter/snow_ground_dark.png';

  static const squishyBearLight =
      'assets/themes/squishy_bear/squishy_bear_light.png';
  static const squishyBearDark =
      'assets/themes/squishy_bear/squishy_bear_dark.png';
  static const bearPawLight = 'assets/themes/squishy_bear/bear_paw_light.png';
  static const bearPawDark = 'assets/themes/squishy_bear/bear_paw_dark.png';
  static const softHillsLight =
      'assets/themes/squishy_bear/soft_hills_light.png';
  static const softHillsDark =
      'assets/themes/squishy_bear/soft_hills_dark.png';

  static const strawberryLight =
      'assets/themes/strawberry_milk/strawberry_light.png';
  static const strawberryDark =
      'assets/themes/strawberry_milk/strawberry_dark.png';
  static const milkCartonLight =
      'assets/themes/strawberry_milk/milk_carton_light.png';
  static const milkCartonDark =
      'assets/themes/strawberry_milk/milk_carton_dark.png';
  static const strawLight = 'assets/themes/strawberry_milk/straw_light.png';
  static const strawDark = 'assets/themes/strawberry_milk/straw_dark.png';
  static const milkFoamLight =
      'assets/themes/strawberry_milk/milk_foam_ground_light.png';
  static const milkFoamDark =
      'assets/themes/strawberry_milk/milk_foam_ground_dark.png';

  static const heartBearLight =
      'assets/themes/lovely_bear/heart_bear_light.png';
  static const heartBearDark =
      'assets/themes/lovely_bear/heart_bear_dark.png';
  static const heartBalloonsLight =
      'assets/themes/lovely_bear/heart_balloons_light.png';
  static const heartBalloonsDark =
      'assets/themes/lovely_bear/heart_balloons_dark.png';
  static const loveLetterLight =
      'assets/themes/lovely_bear/love_letter_light.png';
  static const loveLetterDark =
      'assets/themes/lovely_bear/love_letter_dark.png';
  static const loveVillageGroundLight =
      'assets/themes/lovely_bear/love_village_ground_light.png';
  static const loveVillageGroundDark =
      'assets/themes/lovely_bear/love_village_ground_dark.png';

  static const puddlePuppyLight =
      'assets/themes/rainy_day/puddle_jump_puppy_light.png';
  static const puddlePuppyDark =
      'assets/themes/rainy_day/puddle_jump_puppy_dark.png';
  static const rainyUmbrellaLight =
      'assets/themes/rainy_day/rainy_umbrella_light.png';
  static const rainyUmbrellaDark =
      'assets/themes/rainy_day/rainy_umbrella_dark.png';
  static const rainyGroundLight =
      'assets/themes/rainy_day/rainy_ground_light.png';
  static const rainyGroundDark =
      'assets/themes/rainy_day/rainy_ground_dark.png';

  static const puppyGuitaristLight =
      'assets/themes/band/puppy_guitarist_light.png';
  static const puppyGuitaristDark =
      'assets/themes/band/puppy_guitarist_dark.png';
  static const miniDrumKitLight =
      'assets/themes/band/mini_drum_kit_light.png';
  static const miniDrumKitDark =
      'assets/themes/band/mini_drum_kit_dark.png';
  static const stickerAmpLight =
      'assets/themes/band/sticker_amp_light.png';
  static const stickerAmpDark =
      'assets/themes/band/sticker_amp_dark.png';
  static const bandStageGroundLight =
      'assets/themes/band/band_stage_ground_light.png';
  static const bandStageGroundDark =
      'assets/themes/band/band_stage_ground_dark.png';

  static const cloudHouseLight =
      'assets/themes/cloud/cloud_house_light.png';
  static const cloudHouseDark =
      'assets/themes/cloud/cloud_house_dark.png';
  static const cloudSheepLight =
      'assets/themes/cloud/cloud_sheep_light.png';
  static const cloudSheepDark =
      'assets/themes/cloud/cloud_sheep_dark.png';
  static const sleepyMoonLight =
      'assets/themes/cloud/sleepy_moon_light.png';
  static const sleepyMoonDark =
      'assets/themes/cloud/sleepy_moon_dark.png';
  static const cloudVillageGroundLight =
      'assets/themes/cloud/cloud_village_ground_light.png';
  static const cloudVillageGroundDark =
      'assets/themes/cloud/cloud_village_ground_dark.png';

  static const catPileLight = 'assets/themes/cat_village/cat_pile_light.png';
  static const catPileDark = 'assets/themes/cat_village/cat_pile_dark.png';
  static const catBoxLight = 'assets/themes/cat_village/cat_box_light.png';
  static const catBoxDark = 'assets/themes/cat_village/cat_box_dark.png';
  static const catToysLight = 'assets/themes/cat_village/cat_toys_light.png';
  static const catToysDark = 'assets/themes/cat_village/cat_toys_dark.png';
  static const catTownGroundLight =
      'assets/themes/cat_village/cat_town_ground_light.png';
  static const catTownGroundDark =
      'assets/themes/cat_village/cat_town_ground_dark.png';

  static const bakerHamstersLight =
      'assets/themes/hamster_bakery/baker_hamsters_light.png';
  static const bakerHamstersDark =
      'assets/themes/hamster_bakery/baker_hamsters_dark.png';
  static const cuteBreadsLight =
      'assets/themes/hamster_bakery/cute_breads_light.png';
  static const cuteBreadsDark =
      'assets/themes/hamster_bakery/cute_breads_dark.png';
  static const hamsterBreadBasketLight =
      'assets/themes/hamster_bakery/hamster_bread_basket_light.png';
  static const hamsterBreadBasketDark =
      'assets/themes/hamster_bakery/hamster_bread_basket_dark.png';
  static const hamsterBakeryGroundLight =
      'assets/themes/hamster_bakery/hamster_bakery_ground_light.png';
  static const hamsterBakeryGroundDark =
      'assets/themes/hamster_bakery/hamster_bakery_ground_dark.png';

  static const ottersInTubLight =
      'assets/themes/otter_bathhouse/light/otters-in-tub.png';
  static const ottersInTubDark =
      'assets/themes/otter_bathhouse/dark/otters-in-tub.png';
  static const bathToysLight =
      'assets/themes/otter_bathhouse/light/bath-toys.png';
  static const bathToysDark =
      'assets/themes/otter_bathhouse/dark/bath-toys.png';
  static const bubbleOttersLight =
      'assets/themes/otter_bathhouse/light/bubble-otters.png';
  static const bubbleOttersDark =
      'assets/themes/otter_bathhouse/dark/bubble-otters.png';
  static const bottomBathhouseLight =
      'assets/themes/otter_bathhouse/light/bottom-bathhouse.png';
  static const bottomBathhouseDark =
      'assets/themes/otter_bathhouse/dark/bottom-bathhouse.png';

  static const rabbitFlowerStallLight =
      'assets/themes/rabbit_flower_market/light/rabbit-flower-stall.png';
  static const rabbitFlowerStallDark =
      'assets/themes/rabbit_flower_market/dark/rabbit-flower-stall.png';
  static const flowerMarketSuppliesLight =
      'assets/themes/rabbit_flower_market/light/flower-market-supplies.png';
  static const flowerMarketSuppliesDark =
      'assets/themes/rabbit_flower_market/dark/flower-market-supplies.png';
  static const rabbitsInFlowerBasketLight =
      'assets/themes/rabbit_flower_market/light/rabbits-in-flower-basket.png';
  static const rabbitsInFlowerBasketDark =
      'assets/themes/rabbit_flower_market/dark/rabbits-in-flower-basket.png';
  static const bottomFlowerMarketLight =
      'assets/themes/rabbit_flower_market/light/bottom-flower-market.png';
  static const bottomFlowerMarketDark =
      'assets/themes/rabbit_flower_market/dark/bottom-flower-market.png';

  static const bearPancakeCounterLight =
      'assets/themes/bear_pancake_cafe/light/bear-pancake-counter.png';
  static const bearPancakeCounterDark =
      'assets/themes/bear_pancake_cafe/dark/bear-pancake-counter.png';
  static const pancakeCafeSuppliesLight =
      'assets/themes/bear_pancake_cafe/light/pancake-cafe-supplies.png';
  static const pancakeCafeSuppliesDark =
      'assets/themes/bear_pancake_cafe/dark/pancake-cafe-supplies.png';
  static const bearsAndPancakeStackLight =
      'assets/themes/bear_pancake_cafe/light/bears-and-pancake-stack.png';
  static const bearsAndPancakeStackDark =
      'assets/themes/bear_pancake_cafe/dark/bears-and-pancake-stack.png';
  static const bottomPancakeCafeLight =
      'assets/themes/bear_pancake_cafe/light/bottom-pancake-cafe.png';
  static const bottomPancakeCafeDark =
      'assets/themes/bear_pancake_cafe/dark/bottom-pancake-cafe.png';

  static const precacheDecorations = [
    petal90Light,
    petal180Light,
    petal270Light,
    petal90Dark,
    petal180Dark,
    petal270Dark,
    hillsLight,
    hillsDark,
    cloverDecorationLight,
    cloverDecorationDark,
    cloverBottomLight,
    cloverBottomDark,
    fluffyBearFaceLight,
    fluffyBearFaceDark,
    fluffyBearBottomLight,
    fluffyBearBottomDark,
    fluffyRabbitFaceLight,
    fluffyRabbitFaceDark,
    fluffyRabbitBottomLight,
    fluffyRabbitBottomDark,
    pinkHeartFaceLight,
    pinkHeartFaceDark,
    pinkHeartBottomLight,
    pinkHeartBottomDark,
    sunLight,
    sunDark,
    duckLight,
    duckDark,
    shellLight,
    shellDark,
    waveLight,
    waveDark,
    snowmanLight,
    snowmanDark,
    snowflakeLight,
    snowflakeDark,
    snowCloudLight,
    snowCloudDark,
    snowGroundLight,
    snowGroundDark,
    squishyBearLight,
    squishyBearDark,
    bearPawLight,
    bearPawDark,
    softHillsLight,
    softHillsDark,
    strawberryLight,
    strawberryDark,
    milkCartonLight,
    milkCartonDark,
    strawLight,
    strawDark,
    milkFoamLight,
    milkFoamDark,
    heartBearLight,
    heartBearDark,
    heartBalloonsLight,
    heartBalloonsDark,
    loveLetterLight,
    loveLetterDark,
    loveVillageGroundLight,
    loveVillageGroundDark,
    puddlePuppyLight,
    puddlePuppyDark,
    rainyUmbrellaLight,
    rainyUmbrellaDark,
    rainyGroundLight,
    rainyGroundDark,
    puppyGuitaristLight,
    puppyGuitaristDark,
    miniDrumKitLight,
    miniDrumKitDark,
    stickerAmpLight,
    stickerAmpDark,
    bandStageGroundLight,
    bandStageGroundDark,
    cloudHouseLight,
    cloudHouseDark,
    cloudSheepLight,
    cloudSheepDark,
    sleepyMoonLight,
    sleepyMoonDark,
    cloudVillageGroundLight,
    cloudVillageGroundDark,
    catPileLight,
    catPileDark,
    catBoxLight,
    catBoxDark,
    catToysLight,
    catToysDark,
    catTownGroundLight,
    catTownGroundDark,
    bakerHamstersLight,
    bakerHamstersDark,
    cuteBreadsLight,
    cuteBreadsDark,
    hamsterBreadBasketLight,
    hamsterBreadBasketDark,
    hamsterBakeryGroundLight,
    hamsterBakeryGroundDark,
    ottersInTubLight,
    ottersInTubDark,
    bathToysLight,
    bathToysDark,
    bubbleOttersLight,
    bubbleOttersDark,
    bottomBathhouseLight,
    bottomBathhouseDark,
    rabbitFlowerStallLight,
    rabbitFlowerStallDark,
    flowerMarketSuppliesLight,
    flowerMarketSuppliesDark,
    rabbitsInFlowerBasketLight,
    rabbitsInFlowerBasketDark,
    bottomFlowerMarketLight,
    bottomFlowerMarketDark,
    bearPancakeCounterLight,
    bearPancakeCounterDark,
    pancakeCafeSuppliesLight,
    pancakeCafeSuppliesDark,
    bearsAndPancakeStackLight,
    bearsAndPancakeStackDark,
    bottomPancakeCafeLight,
    bottomPancakeCafeDark,
  ];

  static const blossomLightFill = Color(0xFFF8E8ED);
  static const blossomDarkFill = Color(0xFF1C1418);
  static const cloverLightFill = Color(0xFFEAF6EC);
  static const cloverDarkFill = Color(0xFF121A14);
  static const fluffyBearLightFill = Color(0xFFEBF8FF);
  static const fluffyBearDarkFill = Color(0xFF101820);
  static const fluffyRabbitLightFill = Color(0xFFFFF2F6);
  static const fluffyRabbitDarkFill = Color(0xFF1A1014);
  static const pinkHeartLightFill = Color(0xFFFFF5F8);
  static const pinkHeartDarkFill = Color(0xFF161014);
  static const summerLightFill = Color(0xFFEAF6FB);
  static const summerDarkFill = Color(0xFF101820);
  static const winterLightFill = Color(0xFFEEF5FB);
  static const winterDarkFill = Color(0xFF12141C);
  static const bearLightFill = Color(0xFFF6EEE6);
  static const bearDarkFill = Color(0xFF15110E);
  static const milkLightFill = Color(0xFFFCEEF1);
  static const milkDarkFill = Color(0xFF1A1215);
  static const lovelyLightFill = Color(0xFFFDEEF2);
  static const lovelyDarkFill = Color(0xFF1A1216);
  static const rainyLightFill = Color(0xFFE6EEF3);
  static const rainyDarkFill = Color(0xFF12161C);
  static const concertLightFill = Color(0xFFF6F0F5);
  static const concertDarkFill = Color(0xFF161318);
  static const fluffyCloudLightFill = Color(0xFFEEF4FC);
  static const fluffyCloudDarkFill = Color(0xFF10141C);
  static const catVillageLightFill = Color(0xFFF7F0E8);
  static const catVillageDarkFill = Color(0xFF15110E);
  static const hamsterBakeryLightFill = Color(0xFFF8F0E4);
  static const hamsterBakeryDarkFill = Color(0xFF16120C);
  static const otterBathhouseLightFill = Color(0xFFF8F0F2);
  static const otterBathhouseDarkFill = Color(0xFF18282B);
  static const rabbitFlowerMarketLightFill = Color(0xFFF7F1EC);
  static const rabbitFlowerMarketDarkFill = Color(0xFF171410);
  static const bearPancakeCafeLightFill = Color(0xFFF8F1E8);
  static const bearPancakeCafeDarkFill = Color(0xFF17130E);

  static Color accentColor(AppSkin skin, bool dark, Color fallback) {
    switch (skin) {
      case AppSkin.classic:
        return fallback;
      case AppSkin.blossom:
        return dark ? const Color(0xFFF0A3B8) : const Color(0xFFE56B8A);
      case AppSkin.clover:
        return dark ? const Color(0xFF7EB989) : const Color(0xFF48A65C);
      case AppSkin.fluffyBear:
        return dark ? const Color(0xFF8BB8D0) : const Color(0xFF6AA8C8);
      case AppSkin.fluffyRabbit:
        return dark ? const Color(0xFFE09BB0) : const Color(0xFFD47A96);
      case AppSkin.pinkHeart:
        return dark ? const Color(0xFFDC9EB5) : const Color(0xFFE86B88);
      case AppSkin.summerBeach:
        return dark ? const Color(0xFF5EC8E8) : const Color(0xFF3BAFD4);
      case AppSkin.snowyWinter:
        return dark ? const Color(0xFF8BB8E8) : const Color(0xFF6A9FD4);
      case AppSkin.squishyBear:
        return dark ? const Color(0xFFD4B08A) : const Color(0xFFC4956A);
      case AppSkin.strawberryMilk:
        return dark ? const Color(0xFFF4A0B8) : const Color(0xFFEE7A9A);
      case AppSkin.lovelyBear:
        return dark ? const Color(0xFFF090A8) : const Color(0xFFE86B88);
      case AppSkin.rainyDay:
        return dark ? const Color(0xFF8AA4B8) : const Color(0xFF6B8A9E);
      case AppSkin.concertDay:
        return dark ? const Color(0xFFC4A0E0) : const Color(0xFFB07AD0);
      case AppSkin.fluffyCloud:
        return dark ? const Color(0xFF8BB4E8) : const Color(0xFF6A9FD4);
      case AppSkin.catVillage:
        return dark ? const Color(0xFFE0A888) : const Color(0xFFD4896A);
      case AppSkin.hamsterBakery:
        return dark ? const Color(0xFFE0B888) : const Color(0xFFD4A06A);
      case AppSkin.otterBathhouse:
        return dark ? const Color(0xFFF0A8BC) : const Color(0xFFE07A96);
      case AppSkin.rabbitFlowerMarket:
        return dark ? const Color(0xFFE8A0B0) : const Color(0xFFD97A90);
      case AppSkin.bearPancakeCafe:
        return dark ? const Color(0xFF8EC4B0) : const Color(0xFF6AAD94);
    }
  }

  static Color fillColor(AppSkin skin, bool dark, Color fallback) {
    switch (skin) {
      case AppSkin.classic:
        return fallback;
      case AppSkin.blossom:
        return dark ? blossomDarkFill : blossomLightFill;
      case AppSkin.clover:
        return dark ? cloverDarkFill : cloverLightFill;
      case AppSkin.fluffyBear:
        return dark ? fluffyBearDarkFill : fluffyBearLightFill;
      case AppSkin.fluffyRabbit:
        return dark ? fluffyRabbitDarkFill : fluffyRabbitLightFill;
      case AppSkin.pinkHeart:
        return dark ? pinkHeartDarkFill : pinkHeartLightFill;
      case AppSkin.summerBeach:
        return dark ? summerDarkFill : summerLightFill;
      case AppSkin.snowyWinter:
        return dark ? winterDarkFill : winterLightFill;
      case AppSkin.squishyBear:
        return dark ? bearDarkFill : bearLightFill;
      case AppSkin.strawberryMilk:
        return dark ? milkDarkFill : milkLightFill;
      case AppSkin.lovelyBear:
        return dark ? lovelyDarkFill : lovelyLightFill;
      case AppSkin.rainyDay:
        return dark ? rainyDarkFill : rainyLightFill;
      case AppSkin.concertDay:
        return dark ? concertDarkFill : concertLightFill;
      case AppSkin.fluffyCloud:
        return dark ? fluffyCloudDarkFill : fluffyCloudLightFill;
      case AppSkin.catVillage:
        return dark ? catVillageDarkFill : catVillageLightFill;
      case AppSkin.hamsterBakery:
        return dark ? hamsterBakeryDarkFill : hamsterBakeryLightFill;
      case AppSkin.otterBathhouse:
        return dark ? otterBathhouseDarkFill : otterBathhouseLightFill;
      case AppSkin.rabbitFlowerMarket:
        return dark ? rabbitFlowerMarketDarkFill : rabbitFlowerMarketLightFill;
      case AppSkin.bearPancakeCafe:
        return dark ? bearPancakeCafeDarkFill : bearPancakeCafeLightFill;
    }
  }

  static List<({String filled, String outlined})> navIcons(AppSkin skin) {
    switch (skin) {
      case AppSkin.classic:
      case AppSkin.blossom:
      case AppSkin.clover:
      case AppSkin.fluffyBear:
      case AppSkin.fluffyRabbit:
      case AppSkin.pinkHeart:
      case AppSkin.summerBeach:
      case AppSkin.snowyWinter:
      case AppSkin.squishyBear:
      case AppSkin.strawberryMilk:
      case AppSkin.lovelyBear:
      case AppSkin.rainyDay:
      case AppSkin.concertDay:
      case AppSkin.fluffyCloud:
      case AppSkin.catVillage:
      case AppSkin.hamsterBakery:
      case AppSkin.otterBathhouse:
      case AppSkin.rabbitFlowerMarket:
      case AppSkin.bearPancakeCafe:
        return const [
          (filled: AppIcons.home, outlined: AppIcons.homeOutlined),
          (filled: AppIcons.calendar, outlined: AppIcons.calendarOutlined),
          (filled: AppIcons.planet, outlined: AppIcons.planetOutlined),
          (filled: AppIcons.office, outlined: AppIcons.officeOutlined),
        ];
    }
  }
}

class AppSkinBackground extends StatelessWidget {
  const AppSkinBackground({
    super.key,
    required this.child,
    this.color,
    this.skin,
    this.customTheme,
    this.liftForNav = true,
    this.scaleByWidth = false,
    this.animate = false,
    this.simple = false,
  });

  static const transitionDuration = Duration(milliseconds: 420);

  final Widget child;
  final Color? color;
  final AppSkin? skin;
  final UserTheme? customTheme;
  final bool liftForNav;
  final bool scaleByWidth;
  final bool animate;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final preference = AppScope.maybeOf(context)?.themePreference;
    if (preference == null) {
      return _buildStack(
        context,
        skin ?? AppSkin.classic,
        custom: customTheme,
      );
    }
    return ListenableBuilder(
      listenable: preference,
      builder: (context, _) {
        return _buildStack(
          context,
          skin ?? preference.skin,
          custom: customTheme ?? (skin == null ? preference.customTheme : null),
        );
      },
    );
  }

  Widget _buildStack(
    BuildContext context,
    AppSkin skin, {
    UserTheme? custom,
  }) {
    final colors = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = custom == null
        ? AppSkinAssets.fillColor(
            skin,
            dark,
            color ?? colors.background,
          )
        : custom.fillColorFor(dark);
    final sparse = simple || PcLayout.isPc;
    final Widget? decorations = custom == null
        ? switch (skin) {
      AppSkin.classic => null,
      AppSkin.blossom => _BlossomDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.clover => _CloverDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.fluffyBear => _FluffyMascotDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
          faceLight: AppSkinAssets.fluffyBearFaceLight,
          faceDark: AppSkinAssets.fluffyBearFaceDark,
          bottomLight: AppSkinAssets.fluffyBearBottomLight,
          bottomDark: AppSkinAssets.fluffyBearBottomDark,
          faceTintLight: const Color(0xFFB7D4E4),
          faceTintDark: const Color(0xFF5A7388),
          hillTintLight: const Color(0xFFDAECF6),
          hillTintDark: const Color(0xFF1C2A36),
        ),
      AppSkin.fluffyRabbit => _FluffyMascotDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
          faceLight: AppSkinAssets.fluffyRabbitFaceLight,
          faceDark: AppSkinAssets.fluffyRabbitFaceDark,
          bottomLight: AppSkinAssets.fluffyRabbitBottomLight,
          bottomDark: AppSkinAssets.fluffyRabbitBottomDark,
          faceTintLight: const Color(0xFFE8B8C8),
          faceTintDark: const Color(0xFF885A6E),
          hillTintLight: const Color(0xFFFADDE6),
          hillTintDark: const Color(0xFF36202A),
        ),
      AppSkin.pinkHeart => _FluffyMascotDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
          faceLight: AppSkinAssets.pinkHeartFaceLight,
          faceDark: AppSkinAssets.pinkHeartFaceDark,
          bottomLight: AppSkinAssets.pinkHeartBottomLight,
          bottomDark: AppSkinAssets.pinkHeartBottomDark,
          faceTintLight: const Color(0xFFF0C4D0),
          faceTintDark: const Color(0xFFDC9EB5),
          hillTintLight: const Color(0xFFFCE7ED),
          hillTintDark: const Color(0xFF5D3A49),
        ),
      AppSkin.summerBeach => _SummerBeachDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.snowyWinter => _SnowyWinterDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.squishyBear => _SquishyBearDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.strawberryMilk => _StrawberryMilkDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.lovelyBear => _LovelyBearDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.rainyDay => _RainyDayDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.concertDay => _ConcertDayDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.fluffyCloud => _FluffyCloudDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.catVillage => _CatVillageDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.hamsterBakery => _HamsterBakeryDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.otterBathhouse => _OtterBathhouseDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.rabbitFlowerMarket => _RabbitFlowerMarketDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
      AppSkin.bearPancakeCafe => _BearPancakeCafeDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: sparse,
        ),
    }
        : custom.kind == UserThemeKind.photo
            ? _CustomPhotoDecorations(
                path: custom.photoPath,
                dark: dark,
                wash: custom.photoWash,
              )
            : _CustomPatternDecorations(
                decorationPath: custom.decorationPath,
                bottomPath: custom.bottomPath,
                liftForNav: liftForNav,
                scaleByWidth: scaleByWidth,
                simple: sparse,
              );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (animate)
          AnimatedContainer(
            duration: transitionDuration,
            curve: Curves.easeInOut,
            color: fill,
          )
        else
          ColoredBox(color: fill),
        if (animate)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return currentChild ?? const SizedBox.expand();
            },
            child: KeyedSubtree(
              key: ValueKey(
                '${custom?.id ?? skin.name}-${custom?.kind.name ?? ''}',
              ),
              child: decorations ?? const SizedBox.expand(),
            ),
          )
        else if (decorations != null)
          decorations,
        child,
      ],
    );
  }
}

class _CustomPhotoDecorations extends StatelessWidget {
  const _CustomPhotoDecorations({
    required this.path,
    required this.dark,
    required this.wash,
  });

  final String path;
  final bool dark;
  final double wash;

  @override
  Widget build(BuildContext context) {
    if (!localFileExists(path)) return const SizedBox.expand();
    final amount = wash.clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        LocalFileImage(
          path,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        ),
        if (amount > 0)
          ColoredBox(
            color: (dark ? Colors.black : Colors.white).withValues(alpha: amount),
          ),
      ],
    );
  }
}

class _CustomPatternDecorations extends StatelessWidget {
  const _CustomPatternDecorations({
    required this.decorationPath,
    required this.bottomPath,
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final String decorationPath;
  final String bottomPath;
  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth ? width : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final motifBottom = liftForNav ? 66 + paddingBottom : height * 0.04;
        final hillsHeight = _SkinGround.heightOf(
          width,
          height,
          assetRatio: 600 / 2000,
          maxFraction: 0.32,
        );

        Widget motif({double angle = 0}) {
          if (!localFileExists(decorationPath)) {
            return const SizedBox.shrink();
          }
          Widget child = LocalFileImage(
            decorationPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
          if (angle != 0) {
            child = Transform.rotate(angle: angle, child: child);
          }
          return child;
        }

        return IgnorePointer(
          child: Stack(
            children: [
              if (bottomPath.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: hillsHeight,
                  child: _SkinGround.coverFile(
                    bottomPath,
                    width: width,
                    bandHeight: hillsHeight,
                    assetRatio: 600 / 2000,
                  ),
                ),
              if (decorationPath.isNotEmpty) ...[
                Positioned(
                  top: span * 0.02,
                  right: span * 0.02,
                  width: span * (simple ? 0.16 : 0.24),
                  child: motif(angle: math.pi / 8),
                ),
                Positioned(
                  left: span * 0.02,
                  top: span * (simple ? 0.06 : 0.16),
                  width: span * (simple ? 0.13 : 0.16),
                  child: motif(angle: -math.pi / 7),
                ),
                Positioned(
                  left: span * 0.06,
                  bottom: motifBottom,
                  width: span * (simple ? 0.14 : 0.2),
                  child: motif(angle: math.pi / 5),
                ),
                if (!simple) ...[
                  Positioned(
                    right: span * 0.04,
                    bottom: motifBottom + span * 0.08,
                    width: span * (simple ? 0.13 : 0.16),
                    child: motif(angle: -math.pi / 10),
                  ),
                  Positioned(
                    top: height * (simple ? 0.32 : 0.38),
                    right: span * (simple ? 0.1 : 0.08),
                    width: span * (simple ? 0.12 : 0.15),
                    child: motif(angle: math.pi / 9),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

abstract final class _SkinGround {
  static double heightOf(
    double width,
    double height, {
    double assetRatio = 887 / 1774,
    double maxFraction = 0.34,
  }) {
    final squat = width > height * 0.72;
    final cap = height * (squat ? 0.22 : maxFraction);
    return (width * assetRatio).clamp(0.0, cap);
  }

  static Widget cover(
    String asset, {
    required double width,
    required double bandHeight,
    double assetRatio = 887 / 1774,
  }) {
    return _fade(
      bandHeight: bandHeight,
      natural: width * assetRatio,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  static Widget coverFile(
    String path, {
    required double width,
    required double bandHeight,
    double assetRatio = 887 / 1774,
  }) {
    if (!localFileExists(path)) return const SizedBox.expand();
    return _fade(
      bandHeight: bandHeight,
      natural: width * assetRatio,
      child: LocalFileImage(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );
  }

  static Widget _fade({
    required double bandHeight,
    required double natural,
    required Widget child,
  }) {
    final cropped =
        natural <= 0 ? 0.0 : (1 - bandHeight / natural).clamp(0.0, 1.0);
    final fadeEnd = (0.12 + cropped * 0.78).clamp(0.12, 0.55);
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
          stops: [0, fadeEnd],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

class _LogoSafe {
  _LogoSafe({
    required double screenWidth,
    required double paddingTop,
    required this.enabled,
  })  : logoRight = 200,
        logoBottom = paddingTop + 88,
        actionsLeft = screenWidth - 148;

  final bool enabled;
  final double logoRight;
  final double logoBottom;
  final double actionsLeft;

  Positioned topLeft({
    required double left,
    required double top,
    required double width,
    required Widget child,
  }) {
    var x = left;
    var y = top;
    if (enabled && x < logoRight && y < logoBottom) {
      final shifted = logoRight + 8;
      if (shifted + width <= actionsLeft) {
        x = shifted;
      } else {
        y = logoBottom + 4;
      }
    }
    return Positioned(
      left: x,
      top: y,
      width: width,
      child: child,
    );
  }
}

class _BlossomDecorations extends StatelessWidget {
  const _BlossomDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final petalBottom = liftForNav ? 66 + paddingBottom : height * 0.04;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final petal90 = dark
            ? AppSkinAssets.petal90Dark
            : AppSkinAssets.petal90Light;
        final petal180 = dark
            ? AppSkinAssets.petal180Dark
            : AppSkinAssets.petal180Light;
        final petal270 = dark
            ? AppSkinAssets.petal270Dark
            : AppSkinAssets.petal270Light;
        final hills = dark
            ? AppSkinAssets.hillsDark
            : AppSkinAssets.hillsLight;
        final hillsHeight = _SkinGround.heightOf(
          width,
          height,
          assetRatio: 600 / 2000,
          maxFraction: 0.32,
        );

        Widget petal(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: hillsHeight,
                child: _SkinGround.cover(
                  hills,
                  width: width,
                  bandHeight: hillsHeight,
                  assetRatio: 600 / 2000,
                ),
              ),
              Positioned(
                top: span * 0.02,
                right: span * 0.02,
                width: span * (simple ? 0.18 : 0.26),
                child: petal(petal90),
              ),
              Positioned(
                left: span * 0.02,
                top: span * (simple ? 0.04 : 0.16),
                width: span * (simple ? 0.14 : 0.2),
                child: petal(petal180),
              ),
              Positioned(
                left: span * 0.06,
                bottom: petalBottom,
                width: span * (simple ? 0.16 : 0.22),
                child: petal(petal270),
              ),
              if (!simple)
                Positioned(
                  right: span * 0.04,
                  bottom: petalBottom + span * 0.08,
                  width: span * (simple ? 0.14 : 0.18),
                  child: petal(petal90),
                ),
              if (!simple) ...[
                safe.topLeft(
                  left: span * 0.22,
                  top: span * 0.04,
                  width: span * 0.14,
                  child: petal(petal270),
                ),
                Positioned(
                  top: height * 0.28,
                  right: span * 0.08,
                  width: span * 0.16,
                  child: petal(petal270),
                ),
                safe.topLeft(
                  left: width * 0.5 - span * 0.1,
                  top: height * 0.38,
                  width: span * 0.2,
                  child: petal(petal180),
                ),
                safe.topLeft(
                  left: width * 0.58,
                  top: height * 0.52,
                  width: span * 0.14,
                  child: petal(petal90),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CloverDecorations extends StatelessWidget {
  const _CloverDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final cloverBottomLift = liftForNav ? 66 + paddingBottom : height * 0.04;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final decoration = dark
            ? AppSkinAssets.cloverDecorationDark
            : AppSkinAssets.cloverDecorationLight;
        final hills = dark
            ? AppSkinAssets.cloverBottomDark
            : AppSkinAssets.cloverBottomLight;
        final hillsHeight = _SkinGround.heightOf(
          width,
          height,
          assetRatio: 600 / 2000,
          maxFraction: 0.32,
        );

        Widget clover({double angle = 0}) {
          Widget child = Image.asset(
            decoration,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
          if (angle != 0) {
            child = Transform.rotate(angle: angle, child: child);
          }
          return child;
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: hillsHeight,
                child: _SkinGround.cover(
                  hills,
                  width: width,
                  bandHeight: hillsHeight,
                  assetRatio: 600 / 2000,
                ),
              ),
              Positioned(
                top: span * 0.02,
                right: span * 0.02,
                width: span * (simple ? 0.18 : 0.26),
                child: clover(angle: math.pi / 8),
              ),
              Positioned(
                left: span * 0.02,
                top: span * (simple ? 0.04 : 0.16),
                width: span * (simple ? 0.14 : 0.2),
                child: clover(angle: -math.pi / 7),
              ),
              Positioned(
                left: span * 0.06,
                bottom: cloverBottomLift,
                width: span * (simple ? 0.16 : 0.22),
                child: clover(angle: math.pi / 5),
              ),
              if (!simple)
                Positioned(
                  right: span * 0.04,
                  bottom: cloverBottomLift + span * 0.08,
                  width: span * (simple ? 0.14 : 0.18),
                  child: clover(angle: -math.pi / 10),
                ),
              if (!simple) ...[
                safe.topLeft(
                  left: span * 0.22,
                  top: span * 0.04,
                  width: span * 0.14,
                  child: clover(angle: math.pi / 6),
                ),
                Positioned(
                  top: height * 0.28,
                  right: span * 0.08,
                  width: span * 0.16,
                  child: clover(angle: -math.pi / 12),
                ),
                safe.topLeft(
                  left: width * 0.5 - span * 0.1,
                  top: height * 0.38,
                  width: span * 0.2,
                  child: clover(),
                ),
                safe.topLeft(
                  left: width * 0.58,
                  top: height * 0.52,
                  width: span * 0.14,
                  child: clover(angle: math.pi / 9),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FluffyMascotDecorations extends StatelessWidget {
  const _FluffyMascotDecorations({
    required this.liftForNav,
    required this.faceLight,
    required this.faceDark,
    required this.bottomLight,
    required this.bottomDark,
    required this.faceTintLight,
    required this.faceTintDark,
    required this.hillTintLight,
    required this.hillTintDark,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final String faceLight;
  final String faceDark;
  final String bottomLight;
  final String bottomDark;
  final Color faceTintLight;
  final Color faceTintDark;
  final Color hillTintLight;
  final Color hillTintDark;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final faceBottomLift = liftForNav ? 66 + paddingBottom : height * 0.04;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final decoration = dark ? faceDark : faceLight;
        final hills = dark ? bottomDark : bottomLight;
        final faceTint = dark ? faceTintDark : faceTintLight;
        final hillTint = dark ? hillTintDark : hillTintLight;
        final hillsHeight = _SkinGround.heightOf(
          width,
          height,
          assetRatio: 600 / 2000,
          maxFraction: 0.32,
        );

        Widget tinted(String asset, Color color, {BoxFit fit = BoxFit.contain}) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: Image.asset(
              asset,
              fit: fit,
              filterQuality: FilterQuality.medium,
            ),
          );
        }

        Widget face({double angle = 0}) {
          Widget child = Opacity(
            opacity: dark ? 0.55 : 0.42,
            child: tinted(decoration, faceTint),
          );
          if (angle != 0) {
            child = Transform.rotate(angle: angle, child: child);
          }
          return child;
        }

        final compact = scaleByWidth || simple;
        final faces = compact
            ? <Widget>[
                Positioned(
                  top: height * 0.04,
                  right: width * 0.03,
                  width: math.min(width, height) * 0.22,
                  child: face(angle: 0.12),
                ),
                Positioned(
                  left: width * 0.04,
                  bottom: height * 0.08,
                  width: math.min(width, height) * 0.2,
                  child: face(angle: -0.1),
                ),
                Positioned(
                  right: width * 0.08,
                  bottom: height * 0.22,
                  width: math.min(width, height) * 0.16,
                  child: face(angle: 0.06),
                ),
              ]
            : <Widget>[
                Positioned(
                  top: span * 0.02,
                  right: span * 0.02,
                  width: span * 0.36,
                  child: face(angle: 0.12),
                ),
                safe.topLeft(
                  left: span * 0.02,
                  top: span * 0.14,
                  width: span * 0.3,
                  child: face(angle: -0.14),
                ),
                Positioned(
                  left: span * 0.04,
                  bottom: faceBottomLift,
                  width: span * 0.32,
                  child: face(angle: 0.08),
                ),
                Positioned(
                  right: span * 0.03,
                  bottom: faceBottomLift + span * 0.06,
                  width: span * 0.28,
                  child: face(angle: -0.1),
                ),
                Positioned(
                  top: height * 0.32,
                  right: span * 0.06,
                  width: span * 0.3,
                  child: face(angle: 0.06),
                ),
              ];

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: hillsHeight,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(hillTint, BlendMode.srcIn),
                  child: _SkinGround.cover(
                    hills,
                    width: width,
                    bandHeight: hillsHeight,
                    assetRatio: 600 / 2000,
                  ),
                ),
              ),
              ...faces,
            ],
          ),
        );
      },
    );
  }
}

class _SummerBeachDecorations extends StatelessWidget {
  const _SummerBeachDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final sun = dark ? AppSkinAssets.sunDark : AppSkinAssets.sunLight;
        final duck = dark ? AppSkinAssets.duckDark : AppSkinAssets.duckLight;
        final shell =
            dark ? AppSkinAssets.shellDark : AppSkinAssets.shellLight;
        final wave = dark ? AppSkinAssets.waveDark : AppSkinAssets.waveLight;
        final waveHeight = _SkinGround.heightOf(
          width,
          height,
          assetRatio: 700 / 2000,
        );

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: waveHeight,
                child: _SkinGround.cover(
                  wave,
                  width: width,
                  bandHeight: waveHeight,
                  assetRatio: 700 / 2000,
                ),
              ),
              if (!simple)
              Positioned(
                left: 0,
                bottom: groundBottom,
                width: span * 1.12,
                child: sticker(shell),
              ),
              Positioned(
                right: span * 0.05,
                bottom: groundBottom + span * 0.02,
                width: span * 0.28,
                child: sticker(duck),
              ),
              Positioned(
                top: span * 0.03,
                right: span * 0.03,
                width: span * 0.24,
                child: sticker(sun),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SnowyWinterDecorations extends StatelessWidget {
  const _SnowyWinterDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final snowman =
            dark ? AppSkinAssets.snowmanDark : AppSkinAssets.snowmanLight;
        final flake =
            dark ? AppSkinAssets.snowflakeDark : AppSkinAssets.snowflakeLight;
        final cloud =
            dark ? AppSkinAssets.snowCloudDark : AppSkinAssets.snowCloudLight;
        final ground = dark
            ? AppSkinAssets.snowGroundDark
            : AppSkinAssets.snowGroundLight;
        final groundHeight = _SkinGround.heightOf(
          width,
          height,
          maxFraction: 0.32,
        );

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple) ...[
                Positioned(
                  top: span * 0.02,
                  right: span * 0.04,
                  width: span * 0.16,
                  child: sticker(flake),
                ),
                safe.topLeft(
                  left: span * 0.08,
                  top: span * 0.14,
                  width: span * 0.12,
                  child: sticker(flake),
                ),
                Positioned(
                  top: height * 0.26,
                  right: span * 0.18,
                  width: span * 0.14,
                  child: sticker(flake),
                ),
                safe.topLeft(
                  left: width * 0.42,
                  top: height * 0.4,
                  width: span * 0.18,
                  child: sticker(flake),
                ),
                safe.topLeft(
                  left: span * 0.02,
                  top: span * 0.02,
                  width: span * 0.3,
                  child: sticker(cloud),
                ),
              ],
              Positioned(
                right: span * 0.04,
                bottom: groundBottom,
                width: span * 0.28,
                child: sticker(snowman),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SquishyBearDecorations extends StatelessWidget {
  const _SquishyBearDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final bear = dark
            ? AppSkinAssets.squishyBearDark
            : AppSkinAssets.squishyBearLight;
        final paw =
            dark ? AppSkinAssets.bearPawDark : AppSkinAssets.bearPawLight;
        final hills = dark
            ? AppSkinAssets.softHillsDark
            : AppSkinAssets.softHillsLight;
        final hillsHeight = _SkinGround.heightOf(
          width,
          height,
          maxFraction: 0.32,
        );

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: hillsHeight,
                child: _SkinGround.cover(
                  hills,
                  width: width,
                  bandHeight: hillsHeight,
                ),
              ),
              if (!simple) ...[
                Positioned(
                  top: span * 0.04,
                  right: span * 0.06,
                  width: span * 0.16,
                  child: sticker(paw),
                ),
                safe.topLeft(
                  left: span * 0.08,
                  top: span * 0.16,
                  width: span * 0.13,
                  child: sticker(paw),
                ),
                safe.topLeft(
                  left: width * 0.46,
                  top: height * 0.36,
                  width: span * 0.15,
                  child: sticker(paw),
                ),
                Positioned(
                  top: height * 0.52,
                  right: span * 0.2,
                  width: span * 0.12,
                  child: sticker(paw),
                ),
              ],
              Positioned(
                right: span * 0.04,
                bottom: groundBottom,
                width: span * 0.3,
                child: sticker(bear),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StrawberryMilkDecorations extends StatelessWidget {
  const _StrawberryMilkDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final berry = dark
            ? AppSkinAssets.strawberryDark
            : AppSkinAssets.strawberryLight;
        final carton = dark
            ? AppSkinAssets.milkCartonDark
            : AppSkinAssets.milkCartonLight;
        final straw =
            dark ? AppSkinAssets.strawDark : AppSkinAssets.strawLight;
        final foam = dark
            ? AppSkinAssets.milkFoamDark
            : AppSkinAssets.milkFoamLight;
        final foamHeight = _SkinGround.heightOf(
          width,
          height,
          maxFraction: 0.32,
        );

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: foamHeight,
                child: _SkinGround.cover(
                  foam,
                  width: width,
                  bandHeight: foamHeight,
                ),
              ),
              if (!simple) ...[
                Positioned(
                  top: span * 0.03,
                  right: span * 0.04,
                  width: span * 0.16,
                  child: sticker(berry),
                ),
                safe.topLeft(
                  left: span * 0.06,
                  top: span * 0.14,
                  width: span * 0.13,
                  child: sticker(berry),
                ),
                safe.topLeft(
                  left: width * 0.44,
                  top: height * 0.34,
                  width: span * 0.15,
                  child: sticker(berry),
                ),
                safe.topLeft(
                  left: span * 0.1,
                  top: height * 0.5,
                  width: span * 0.12,
                  child: sticker(berry),
                ),
                safe.topLeft(
                  left: span * 0.28,
                  top: span * 0.05,
                  width: span * 0.18,
                  child: sticker(straw),
                ),
              ],
              Positioned(
                right: span * 0.04,
                bottom: groundBottom,
                width: span * 0.28,
                child: sticker(carton),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LovelyBearDecorations extends StatelessWidget {
  const _LovelyBearDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final bear = dark
            ? AppSkinAssets.heartBearDark
            : AppSkinAssets.heartBearLight;
        final balloons = dark
            ? AppSkinAssets.heartBalloonsDark
            : AppSkinAssets.heartBalloonsLight;
        final letter = dark
            ? AppSkinAssets.loveLetterDark
            : AppSkinAssets.loveLetterLight;
        final ground = dark
            ? AppSkinAssets.loveVillageGroundDark
            : AppSkinAssets.loveVillageGroundLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple) ...[
                safe.topLeft(
                  left: span * 0.03,
                  top: span * 0.02,
                  width: span * 0.26,
                  child: sticker(balloons),
                ),
                Positioned(
                  left: span * 0.04,
                  bottom: groundBottom + span * 0.02,
                  width: span * 0.22,
                  child: sticker(letter),
                ),
              ],
              Positioned(
                right: span * 0.03,
                bottom: groundBottom,
                width: span * 0.32,
                child: sticker(bear),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RainyDayDecorations extends StatelessWidget {
  const _RainyDayDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final puppy = dark
            ? AppSkinAssets.puddlePuppyDark
            : AppSkinAssets.puddlePuppyLight;
        final umbrella = dark
            ? AppSkinAssets.rainyUmbrellaDark
            : AppSkinAssets.rainyUmbrellaLight;
        final ground = dark
            ? AppSkinAssets.rainyGroundDark
            : AppSkinAssets.rainyGroundLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple)
                safe.topLeft(
                  left: span * 0.03,
                  top: span * 0.02,
                  width: span * 0.24,
                  child: sticker(umbrella),
                ),
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: sticker(puppy),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConcertDayDecorations extends StatelessWidget {
  const _ConcertDayDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final size = (span * 0.52).clamp(0.0, height * 0.56);
        final guitarist = dark
            ? AppSkinAssets.puppyGuitaristDark
            : AppSkinAssets.puppyGuitaristLight;
        final ground = dark
            ? AppSkinAssets.bandStageGroundDark
            : AppSkinAssets.bandStageGroundLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              Positioned(
                left: (width - size) / 2,
                bottom: groundBottom,
                width: size,
                child: Image.asset(
                  guitarist,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FluffyCloudDecorations extends StatelessWidget {
  const _FluffyCloudDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final house = dark
            ? AppSkinAssets.cloudHouseDark
            : AppSkinAssets.cloudHouseLight;
        final sheep = dark
            ? AppSkinAssets.cloudSheepDark
            : AppSkinAssets.cloudSheepLight;
        final moon = dark
            ? AppSkinAssets.sleepyMoonDark
            : AppSkinAssets.sleepyMoonLight;
        final ground = dark
            ? AppSkinAssets.cloudVillageGroundDark
            : AppSkinAssets.cloudVillageGroundLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple)
                Positioned(
                  top: span * 0.03,
                  right: span * 0.04,
                  width: span * 0.24,
                  child: sticker(moon),
                ),
              Positioned(
                left: span * 0.03,
                bottom: groundBottom + span * 0.02,
                width: span * 0.26,
                child: sticker(sheep),
              ),
              Positioned(
                right: span * 0.03,
                bottom: groundBottom,
                width: span * 0.32,
                child: sticker(house),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatVillageDecorations extends StatelessWidget {
  const _CatVillageDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final pile =
            dark ? AppSkinAssets.catPileDark : AppSkinAssets.catPileLight;
        final box =
            dark ? AppSkinAssets.catBoxDark : AppSkinAssets.catBoxLight;
        final toys =
            dark ? AppSkinAssets.catToysDark : AppSkinAssets.catToysLight;
        final ground = dark
            ? AppSkinAssets.catTownGroundDark
            : AppSkinAssets.catTownGroundLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple)
                safe.topLeft(
                  left: span * 0.04,
                  top: span * 0.02,
                  width: span * 0.28,
                  child: sticker(toys),
                ),
              Positioned(
                left: span * 0.02,
                bottom: groundBottom + span * 0.02,
                width: span * 0.28,
                child: sticker(box),
              ),
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: sticker(pile),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HamsterBakeryDecorations extends StatelessWidget {
  const _HamsterBakeryDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final bakers = dark
            ? AppSkinAssets.bakerHamstersDark
            : AppSkinAssets.bakerHamstersLight;
        final basket = dark
            ? AppSkinAssets.hamsterBreadBasketDark
            : AppSkinAssets.hamsterBreadBasketLight;
        final breads = dark
            ? AppSkinAssets.cuteBreadsDark
            : AppSkinAssets.cuteBreadsLight;
        final ground = dark
            ? AppSkinAssets.hamsterBakeryGroundDark
            : AppSkinAssets.hamsterBakeryGroundLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple)
                safe.topLeft(
                  left: span * 0.04,
                  top: span * 0.02,
                  width: span * 0.28,
                  child: sticker(breads),
                ),
              Positioned(
                left: span * 0.02,
                bottom: groundBottom + span * 0.02,
                width: span * 0.28,
                child: sticker(basket),
              ),
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: sticker(bakers),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtterBathhouseDecorations extends StatelessWidget {
  const _OtterBathhouseDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final tub = dark
            ? AppSkinAssets.ottersInTubDark
            : AppSkinAssets.ottersInTubLight;
        final toys = dark
            ? AppSkinAssets.bathToysDark
            : AppSkinAssets.bathToysLight;
        final bubbles = dark
            ? AppSkinAssets.bubbleOttersDark
            : AppSkinAssets.bubbleOttersLight;
        final ground = dark
            ? AppSkinAssets.bottomBathhouseDark
            : AppSkinAssets.bottomBathhouseLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple)
                safe.topLeft(
                  left: span * 0.04,
                  top: span * 0.02,
                  width: span * 0.28,
                  child: sticker(bubbles),
                ),
              Positioned(
                left: span * 0.02,
                bottom: groundBottom + span * 0.02,
                width: span * 0.28,
                child: sticker(toys),
              ),
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: sticker(tub),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RabbitFlowerMarketDecorations extends StatelessWidget {
  const _RabbitFlowerMarketDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final stall = dark
            ? AppSkinAssets.rabbitFlowerStallDark
            : AppSkinAssets.rabbitFlowerStallLight;
        final supplies = dark
            ? AppSkinAssets.flowerMarketSuppliesDark
            : AppSkinAssets.flowerMarketSuppliesLight;
        final basket = dark
            ? AppSkinAssets.rabbitsInFlowerBasketDark
            : AppSkinAssets.rabbitsInFlowerBasketLight;
        final ground = dark
            ? AppSkinAssets.bottomFlowerMarketDark
            : AppSkinAssets.bottomFlowerMarketLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple)
                safe.topLeft(
                  left: span * 0.04,
                  top: span * 0.02,
                  width: span * 0.28,
                  child: sticker(basket),
                ),
              Positioned(
                left: span * 0.02,
                bottom: groundBottom + span * 0.02,
                width: span * 0.28,
                child: sticker(supplies),
              ),
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: sticker(stall),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BearPancakeCafeDecorations extends StatelessWidget {
  const _BearPancakeCafeDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final safe = _LogoSafe(
          screenWidth: width,
          paddingTop: MediaQuery.paddingOf(context).top,
          enabled: !simple,
        );
        final counter = dark
            ? AppSkinAssets.bearPancakeCounterDark
            : AppSkinAssets.bearPancakeCounterLight;
        final supplies = dark
            ? AppSkinAssets.pancakeCafeSuppliesDark
            : AppSkinAssets.pancakeCafeSuppliesLight;
        final stack = dark
            ? AppSkinAssets.bearsAndPancakeStackDark
            : AppSkinAssets.bearsAndPancakeStackLight;
        final ground = dark
            ? AppSkinAssets.bottomPancakeCafeDark
            : AppSkinAssets.bottomPancakeCafeLight;
        final groundHeight = _SkinGround.heightOf(width, height);

        Widget sticker(String asset) {
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundHeight,
                child: _SkinGround.cover(
                  ground,
                  width: width,
                  bandHeight: groundHeight,
                ),
              ),
              if (!simple)
                safe.topLeft(
                  left: span * 0.04,
                  top: span * 0.02,
                  width: span * 0.28,
                  child: sticker(stack),
                ),
              Positioned(
                left: span * 0.02,
                bottom: groundBottom + span * 0.02,
                width: span * 0.28,
                child: sticker(supplies),
              ),
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: sticker(counter),
              ),
            ],
          ),
        );
      },
    );
  }
}
