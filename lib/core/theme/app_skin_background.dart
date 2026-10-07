import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pluto/app_scope.dart';
import 'package:pluto/core/constants/app_icons.dart';
import 'package:pluto/core/layout/pc_layout.dart';
import 'package:pluto/core/theme/app_colors.dart';
import 'package:pluto/data/datasources/theme_preference.dart';
import 'package:pluto/presentation/widgets/local_file_image.dart';

class AppSkinAssets {
  AppSkinAssets._();

  static const petal90Light =
      'assets/themes/blossom/petal_single_light_90deg.webp';
  static const petal180Light =
      'assets/themes/blossom/petal_single_light_180deg.webp';
  static const petal270Light =
      'assets/themes/blossom/petal_single_light_270deg.webp';
  static const petal90Dark =
      'assets/themes/blossom/petal_single_dark_90deg.webp';
  static const petal180Dark =
      'assets/themes/blossom/petal_single_dark_180deg.webp';
  static const petal270Dark =
      'assets/themes/blossom/petal_single_dark_270deg.webp';
  static const hillsLight =
      'assets/themes/blossom/blossom_bottom_hills_light.webp';
  static const hillsDark =
      'assets/themes/blossom/blossom_bottom_hills_dark.webp';

  static const cloverDecorationLight =
      'assets/themes/clover/clover_decoration_light.webp';
  static const cloverDecorationDark =
      'assets/themes/clover/clover_decoration_dark.webp';
  static const cloverBottomLight =
      'assets/themes/clover/clover_bottom_light.webp';
  static const cloverBottomDark =
      'assets/themes/clover/clover_bottom_dark.webp';

  static const fluffyBearFaceLight =
      'assets/themes/fluffy_bear/bear_face_decoration_light.webp';
  static const fluffyBearFaceDark =
      'assets/themes/fluffy_bear/bear_face_decoration_dark.webp';
  static const fluffyBearBottomLight =
      'assets/themes/fluffy_bear/bear_face_bottom_light.webp';
  static const fluffyBearBottomDark =
      'assets/themes/fluffy_bear/bear_face_bottom_dark.webp';

  static const fluffyRabbitFaceLight =
      'assets/themes/fluffy_rabbit/bunny_face_decoration_light.webp';
  static const fluffyRabbitFaceDark =
      'assets/themes/fluffy_rabbit/bunny_face_decoration_dark.webp';
  static const fluffyRabbitBottomLight =
      'assets/themes/fluffy_rabbit/bunny_face_bottom_light.webp';
  static const fluffyRabbitBottomDark =
      'assets/themes/fluffy_rabbit/bunny_face_bottom_dark.webp';

  static const pinkHeartFaceLight =
      'assets/themes/pink_heart/heart_decoration_light.webp';
  static const pinkHeartFaceDark =
      'assets/themes/pink_heart/heart_decoration_dark.webp';
  static const pinkHeartBottomLight =
      'assets/themes/pink_heart/heart_bottom_light.webp';
  static const pinkHeartBottomDark =
      'assets/themes/pink_heart/heart_bottom_dark.webp';

  static const sunLight = 'assets/themes/summer_beach/summer_sun_light.webp';
  static const sunDark = 'assets/themes/summer_beach/summer_sun_dark.webp';
  static const duckLight = 'assets/themes/summer_beach/duck_ring_light.webp';
  static const duckDark = 'assets/themes/summer_beach/duck_ring_dark.webp';
  static const shellLight = 'assets/themes/summer_beach/shell_star_light.webp';
  static const shellDark = 'assets/themes/summer_beach/shell_star_dark.webp';
  static const waveLight =
      'assets/themes/summer_beach/sea_wave_bottom_light.webp';
  static const waveDark =
      'assets/themes/summer_beach/sea_wave_bottom_dark.webp';

  static const snowmanLight = 'assets/themes/snowy_winter/snowman_light.webp';
  static const snowmanDark = 'assets/themes/snowy_winter/snowman_dark.webp';
  static const snowflakeLight =
      'assets/themes/snowy_winter/snowflake_light.webp';
  static const snowflakeDark = 'assets/themes/snowy_winter/snowflake_dark.webp';
  static const snowCloudLight =
      'assets/themes/snowy_winter/snow_cloud_light.webp';
  static const snowCloudDark = 'assets/themes/snowy_winter/snow_cloud_dark.webp';
  static const snowGroundLight =
      'assets/themes/snowy_winter/snow_ground_light.webp';
  static const snowGroundDark =
      'assets/themes/snowy_winter/snow_ground_dark.webp';

  static const squishyBearLight =
      'assets/themes/squishy_bear/squishy_bear_light.webp';
  static const squishyBearDark =
      'assets/themes/squishy_bear/squishy_bear_dark.webp';
  static const bearPawLight = 'assets/themes/squishy_bear/bear_paw_light.webp';
  static const bearPawDark = 'assets/themes/squishy_bear/bear_paw_dark.webp';
  static const softHillsLight =
      'assets/themes/squishy_bear/soft_hills_light.webp';
  static const softHillsDark =
      'assets/themes/squishy_bear/soft_hills_dark.webp';

  static const strawberryLight =
      'assets/themes/strawberry_milk/strawberry_light.webp';
  static const strawberryDark =
      'assets/themes/strawberry_milk/strawberry_dark.webp';
  static const milkCartonLight =
      'assets/themes/strawberry_milk/milk_carton_light.webp';
  static const milkCartonDark =
      'assets/themes/strawberry_milk/milk_carton_dark.webp';
  static const strawLight = 'assets/themes/strawberry_milk/straw_light.webp';
  static const strawDark = 'assets/themes/strawberry_milk/straw_dark.webp';
  static const milkFoamLight =
      'assets/themes/strawberry_milk/milk_foam_ground_light.webp';
  static const milkFoamDark =
      'assets/themes/strawberry_milk/milk_foam_ground_dark.webp';

  static const heartBearLight =
      'assets/themes/lovely_bear/heart_bear_light.webp';
  static const heartBearDark =
      'assets/themes/lovely_bear/heart_bear_dark.webp';
  static const heartBalloonsLight =
      'assets/themes/lovely_bear/heart_balloons_light.webp';
  static const heartBalloonsDark =
      'assets/themes/lovely_bear/heart_balloons_dark.webp';
  static const loveLetterLight =
      'assets/themes/lovely_bear/love_letter_light.webp';
  static const loveLetterDark =
      'assets/themes/lovely_bear/love_letter_dark.webp';
  static const loveVillageGroundLight =
      'assets/themes/lovely_bear/love_village_ground_light.webp';
  static const loveVillageGroundDark =
      'assets/themes/lovely_bear/love_village_ground_dark.webp';

  static const puddlePuppyLight =
      'assets/themes/rainy_day/puddle_jump_puppy_light.webp';
  static const puddlePuppyDark =
      'assets/themes/rainy_day/puddle_jump_puppy_dark.webp';
  static const rainyGroundLight =
      'assets/themes/rainy_day/rainy_ground_light.webp';
  static const rainyGroundDark =
      'assets/themes/rainy_day/rainy_ground_dark.webp';

  static const puppyGuitaristLight =
      'assets/themes/band/puppy_guitarist_light.webp';
  static const puppyGuitaristDark =
      'assets/themes/band/puppy_guitarist_dark.webp';
  static const miniDrumKitLight =
      'assets/themes/band/mini_drum_kit_light.webp';
  static const miniDrumKitDark =
      'assets/themes/band/mini_drum_kit_dark.webp';
  static const stickerAmpLight =
      'assets/themes/band/sticker_amp_light.webp';
  static const stickerAmpDark =
      'assets/themes/band/sticker_amp_dark.webp';
  static const bandStageGroundLight =
      'assets/themes/band/band_stage_ground_light.webp';
  static const bandStageGroundDark =
      'assets/themes/band/band_stage_ground_dark.webp';

  static const cloudHouseLight =
      'assets/themes/cloud/cloud_house_light.webp';
  static const cloudHouseDark =
      'assets/themes/cloud/cloud_house_dark.webp';
  static const cloudSheepLight =
      'assets/themes/cloud/cloud_sheep_light.webp';
  static const cloudSheepDark =
      'assets/themes/cloud/cloud_sheep_dark.webp';
  static const sleepyMoonLight =
      'assets/themes/cloud/sleepy_moon_light.webp';
  static const sleepyMoonDark =
      'assets/themes/cloud/sleepy_moon_dark.webp';
  static const cloudVillageGroundLight =
      'assets/themes/cloud/cloud_village_ground_light.webp';
  static const cloudVillageGroundDark =
      'assets/themes/cloud/cloud_village_ground_dark.webp';

  static const catPileLight = 'assets/themes/cat_village/cat_pile_light.webp';
  static const catPileDark = 'assets/themes/cat_village/cat_pile_dark.webp';
  static const catBoxLight = 'assets/themes/cat_village/cat_box_light.webp';
  static const catBoxDark = 'assets/themes/cat_village/cat_box_dark.webp';
  static const catToysLight = 'assets/themes/cat_village/cat_toys_light.webp';
  static const catToysDark = 'assets/themes/cat_village/cat_toys_dark.webp';
  static const catTownGroundLight =
      'assets/themes/cat_village/cat_town_ground_light.webp';
  static const catTownGroundDark =
      'assets/themes/cat_village/cat_town_ground_dark.webp';

  static const bakerHamstersLight =
      'assets/themes/hamster_bakery/baker_hamsters_light.webp';
  static const bakerHamstersDark =
      'assets/themes/hamster_bakery/baker_hamsters_dark.webp';
  static const cuteBreadsLight =
      'assets/themes/hamster_bakery/cute_breads_light.webp';
  static const cuteBreadsDark =
      'assets/themes/hamster_bakery/cute_breads_dark.webp';
  static const hamsterBreadBasketLight =
      'assets/themes/hamster_bakery/hamster_bread_basket_light.webp';
  static const hamsterBreadBasketDark =
      'assets/themes/hamster_bakery/hamster_bread_basket_dark.webp';
  static const hamsterBakeryGroundLight =
      'assets/themes/hamster_bakery/hamster_bakery_ground_light.webp';
  static const hamsterBakeryGroundDark =
      'assets/themes/hamster_bakery/hamster_bakery_ground_dark.webp';

  static const ottersInTubLight =
      'assets/themes/otter_bathhouse/light/otters-in-tub.webp';
  static const ottersInTubDark =
      'assets/themes/otter_bathhouse/dark/otters-in-tub.webp';
  static const bathToysLight =
      'assets/themes/otter_bathhouse/light/bath-toys.webp';
  static const bathToysDark =
      'assets/themes/otter_bathhouse/dark/bath-toys.webp';
  static const bubbleOttersLight =
      'assets/themes/otter_bathhouse/light/bubble-otters.webp';
  static const bubbleOttersDark =
      'assets/themes/otter_bathhouse/dark/bubble-otters.webp';
  static const bottomBathhouseLight =
      'assets/themes/otter_bathhouse/light/bottom-bathhouse.webp';
  static const bottomBathhouseDark =
      'assets/themes/otter_bathhouse/dark/bottom-bathhouse.webp';

  static const rabbitFlowerStallLight =
      'assets/themes/rabbit_flower_market/light/rabbit-flower-stall.webp';
  static const rabbitFlowerStallDark =
      'assets/themes/rabbit_flower_market/dark/rabbit-flower-stall.webp';
  static const flowerMarketSuppliesLight =
      'assets/themes/rabbit_flower_market/light/flower-market-supplies.webp';
  static const flowerMarketSuppliesDark =
      'assets/themes/rabbit_flower_market/dark/flower-market-supplies.webp';
  static const rabbitsInFlowerBasketLight =
      'assets/themes/rabbit_flower_market/light/rabbits-in-flower-basket.webp';
  static const rabbitsInFlowerBasketDark =
      'assets/themes/rabbit_flower_market/dark/rabbits-in-flower-basket.webp';
  static const bottomFlowerMarketLight =
      'assets/themes/rabbit_flower_market/light/bottom-flower-market.webp';
  static const bottomFlowerMarketDark =
      'assets/themes/rabbit_flower_market/dark/bottom-flower-market.webp';

  static const bearPancakeCounterLight =
      'assets/themes/bear_pancake_cafe/light/bear-pancake-counter.webp';
  static const bearPancakeCounterDark =
      'assets/themes/bear_pancake_cafe/dark/bear-pancake-counter.webp';
  static const pancakeCafeSuppliesLight =
      'assets/themes/bear_pancake_cafe/light/pancake-cafe-supplies.webp';
  static const pancakeCafeSuppliesDark =
      'assets/themes/bear_pancake_cafe/dark/pancake-cafe-supplies.webp';
  static const bearsAndPancakeStackLight =
      'assets/themes/bear_pancake_cafe/light/bears-and-pancake-stack.webp';
  static const bearsAndPancakeStackDark =
      'assets/themes/bear_pancake_cafe/dark/bears-and-pancake-stack.webp';
  static const bottomPancakeCafeLight =
      'assets/themes/bear_pancake_cafe/light/bottom-pancake-cafe.webp';
  static const bottomPancakeCafeDark =
      'assets/themes/bear_pancake_cafe/dark/bottom-pancake-cafe.webp';

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
    this.playing = true,
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
  final bool playing;

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
    final sparse = simple || PcLayout.isWideOf(context);
    final compact = simple ||
        (PcLayout.isWideOf(context) && AppSkin.patternSkins.contains(skin));
    final Widget? decorations = custom == null
        ? switch (skin) {
      AppSkin.classic => null,
      AppSkin.blossom => _BlossomDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.clover => _CloverDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.fluffyBear => _FluffyMascotDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
          moves: true,
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
          simple: compact,
          playing: playing,
          moves: true,
          hops: true,
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
          simple: compact,
          playing: playing,
          moves: true,
          beats: true,
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
          simple: compact,
          playing: playing,
        ),
      AppSkin.snowyWinter => _SnowyWinterDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.squishyBear => _SquishyBearDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.strawberryMilk => _StrawberryMilkDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.lovelyBear => _LovelyBearDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.rainyDay => _RainyDayDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.concertDay => _ConcertDayDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.fluffyCloud => _FluffyCloudDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.catVillage => _CatVillageDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.hamsterBakery => _HamsterBakeryDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.otterBathhouse => _OtterBathhouseDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.rabbitFlowerMarket => _RabbitFlowerMarketDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
        ),
      AppSkin.bearPancakeCafe => _BearPancakeCafeDecorations(
          liftForNav: liftForNav,
          scaleByWidth: scaleByWidth,
          simple: compact,
          playing: playing,
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
    if (path.isEmpty) return const SizedBox.expand();
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
          if (decorationPath.isEmpty) {
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
    if (path.isEmpty) return const SizedBox.expand();
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

  ({double left, double top}) pin({
    required double left,
    required double top,
    required double width,
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
    return (left: x, top: y);
  }

  Positioned topLeft({
    required double left,
    required double top,
    required double width,
    required Widget child,
  }) {
    final at = pin(left: left, top: top, width: width);
    return Positioned(
      left: at.left,
      top: at.top,
      width: width,
      child: child,
    );
  }
}

class _BlossomDecorations extends StatefulWidget {
  const _BlossomDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  State<_BlossomDecorations> createState() => _BlossomDecorationsState();
}

class _BlossomDecorationsState extends State<_BlossomDecorations>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final _phase = ValueNotifier<double>(0);
  var _last = Duration.zero;

  static double _cyclesPerSecond(double motion) {
    const slow = 1 / 16;
    const fast = 1 / 3.2;
    return slow + (fast - slow) * motion.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _phase.dispose();
    super.dispose();
  }

  void _syncTicker(double motion) {
    if (motion <= ThemePreference.motionOff) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    _ticker ??= createTicker(_onTick);
    if (!(_ticker?.isActive ?? false)) {
      _last = Duration.zero;
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final motion =
        AppScope.maybeOf(context)?.themePreference.motion ??
            ThemePreference.defaultMotion;
    if (motion <= ThemePreference.motionOff) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    final last = _last == Duration.zero ? elapsed : _last;
    _last = elapsed;
    final dt = (elapsed - last).inMicroseconds / 1000000;
    if (dt <= 0 || dt > 0.08) return;
    _phase.value = (_phase.value + dt * _cyclesPerSecond(motion)) % 1.0;
  }

  Widget _stillPetal(String asset) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }

  Widget _fallPetal({
    required String asset,
    required int index,
    required double t,
    required double motion,
    required double width,
    required double height,
    required double span,
    required double size,
    required double x,
  }) {
    final phase = (t + index * 0.27) % 1.0;
    final travel = height + size * 2.2;
    final top = -size * 1.1 + travel * phase;
    final sway =
        math.sin(phase * math.pi * 3 + index * 1.4) * span * (0.03 + motion * 0.02);
    final angle = phase * math.pi * (1.2 + motion * 0.6) + index * 0.7;
    return Positioned(
      left: (x + sway).clamp(-size, width),
      top: top,
      width: size,
      child: Transform.rotate(
        angle: angle,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final preference = AppScope.maybeOf(context)?.themePreference;
    Widget body() {
      final motion = preference?.motion ?? ThemePreference.defaultMotion;
      _syncTicker(motion);
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final span = widget.scaleByWidth
              ? width
              : constraints.biggest.shortestSide;
          final paddingBottom = MediaQuery.paddingOf(context).bottom;
          final petalBottom =
              widget.liftForNav ? 66 + paddingBottom : height * 0.04;
          final petal90 =
              dark ? AppSkinAssets.petal90Dark : AppSkinAssets.petal90Light;
          final petal180 =
              dark ? AppSkinAssets.petal180Dark : AppSkinAssets.petal180Light;
          final petal270 =
              dark ? AppSkinAssets.petal270Dark : AppSkinAssets.petal270Light;
          final hills = dark ? AppSkinAssets.hillsDark : AppSkinAssets.hillsLight;
          final hillsHeight = _SkinGround.heightOf(
            width,
            height,
            assetRatio: 600 / 2000,
            maxFraction: 0.32,
          );
          final simple = widget.simple;
          Widget petals(double t) {
            if (motion <= ThemePreference.motionOff) {
              return Stack(
                children: [
                  Positioned(
                    top: span * 0.02,
                    right: span * 0.02,
                    width: span * (simple ? 0.18 : 0.26),
                    child: _stillPetal(petal90),
                  ),
                  Positioned(
                    left: span * 0.02,
                    top: span * (simple ? 0.04 : 0.16),
                    width: span * (simple ? 0.14 : 0.2),
                    child: _stillPetal(petal180),
                  ),
                  Positioned(
                    left: span * 0.06,
                    bottom: petalBottom,
                    width: span * (simple ? 0.16 : 0.22),
                    child: _stillPetal(petal270),
                  ),
                  if (!simple)
                    Positioned(
                      right: span * 0.04,
                      bottom: petalBottom + span * 0.08,
                      width: span * 0.18,
                      child: _stillPetal(petal90),
                    ),
                ],
              );
            }
            final sizes = simple
                ? [span * 0.18, span * 0.14, span * 0.16]
                : [span * 0.22, span * 0.18, span * 0.2, span * 0.16];
            final xs = simple
                ? [width - span * 0.22, span * 0.04, span * 0.42]
                : [
                    width - span * 0.26,
                    span * 0.04,
                    span * 0.38,
                    width - span * 0.42,
                  ];
            final assets = [petal90, petal180, petal270, petal90];
            return Stack(
              children: [
                for (var i = 0; i < sizes.length; i++)
                  _fallPetal(
                    asset: assets[i],
                    index: i,
                    t: t,
                    motion: motion,
                    width: width,
                    height: height,
                    span: span,
                    size: sizes[i],
                    x: xs[i],
                  ),
              ],
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
                if (motion <= ThemePreference.motionOff)
                  petals(0)
                else
                  RepaintBoundary(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _phase,
                      builder: (context, t, _) => petals(t),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return TickerMode(
      enabled: widget.playing,
      child: preference == null
          ? body()
          : ListenableBuilder(
              listenable: preference,
              builder: (context, _) => body(),
            ),
    );
  }
}

class _CloverDecorations extends StatefulWidget {
  const _CloverDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  State<_CloverDecorations> createState() => _CloverDecorationsState();
}

class _CloverDecorationsState extends State<_CloverDecorations>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final _phase = ValueNotifier<double>(0);
  var _last = Duration.zero;

  static double _cyclesPerSecond(double motion) {
    const slow = 1 / 7;
    const fast = 1 / 2.4;
    return slow + (fast - slow) * motion.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _phase.dispose();
    super.dispose();
  }

  void _syncTicker(double motion) {
    if (motion <= ThemePreference.motionOff) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    _ticker ??= createTicker(_onTick);
    if (!(_ticker?.isActive ?? false)) {
      _last = Duration.zero;
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final motion =
        AppScope.maybeOf(context)?.themePreference.motion ??
            ThemePreference.defaultMotion;
    if (motion <= ThemePreference.motionOff) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    final last = _last == Duration.zero ? elapsed : _last;
    _last = elapsed;
    final dt = (elapsed - last).inMicroseconds / 1000000;
    if (dt <= 0 || dt > 0.08) return;
    _phase.value = (_phase.value + dt * _cyclesPerSecond(motion)) % 1.0;
  }

  Widget _clover({
    required String asset,
    required int index,
    required double angle,
    required double t,
    required double motion,
  }) {
    Widget child = Image.asset(
      asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    if (motion <= ThemePreference.motionOff) {
      if (angle != 0) child = Transform.rotate(angle: angle, child: child);
      return child;
    }
    final wave = math.sin((t + index * 0.22) * math.pi * 2);
    final wave2 = math.cos((t + index * 0.31) * math.pi * 2);
    final amp = 3.0 + motion * 7.0;
    final tilt = (0.05 + motion * 0.09) * wave;
    return Transform.translate(
      offset: Offset(wave * amp * 0.45, wave2 * amp * 0.35),
      child: Transform.rotate(angle: angle + tilt, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final preference = AppScope.maybeOf(context)?.themePreference;
    Widget body() {
      final motion = preference?.motion ?? ThemePreference.defaultMotion;
      _syncTicker(motion);
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final span = widget.scaleByWidth
              ? width
              : constraints.biggest.shortestSide;
          final paddingBottom = MediaQuery.paddingOf(context).bottom;
          final cloverBottomLift =
              widget.liftForNav ? 66 + paddingBottom : height * 0.04;
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
          final simple = widget.simple;
          Widget clovers(double t) {
            return Stack(
              children: [
                Positioned(
                  top: span * 0.02,
                  right: span * 0.02,
                  width: span * (simple ? 0.18 : 0.26),
                  child: _clover(
                    asset: decoration,
                    index: 0,
                    angle: math.pi / 8,
                    t: t,
                    motion: motion,
                  ),
                ),
                Positioned(
                  left: span * 0.02,
                  top: span * (simple ? 0.04 : 0.16),
                  width: span * (simple ? 0.14 : 0.2),
                  child: _clover(
                    asset: decoration,
                    index: 1,
                    angle: -math.pi / 7,
                    t: t,
                    motion: motion,
                  ),
                ),
                Positioned(
                  left: span * 0.06,
                  bottom: cloverBottomLift,
                  width: span * (simple ? 0.16 : 0.22),
                  child: _clover(
                    asset: decoration,
                    index: 2,
                    angle: math.pi / 5,
                    t: t,
                    motion: motion,
                  ),
                ),
                if (!simple)
                  Positioned(
                    right: span * 0.04,
                    bottom: cloverBottomLift + span * 0.08,
                    width: span * 0.18,
                    child: _clover(
                      asset: decoration,
                      index: 3,
                      angle: -math.pi / 10,
                      t: t,
                      motion: motion,
                    ),
                  ),
              ],
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
                if (motion <= ThemePreference.motionOff)
                  clovers(0)
                else
                  RepaintBoundary(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _phase,
                      builder: (context, t, _) => clovers(t),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return TickerMode(
      enabled: widget.playing,
      child: preference == null
          ? body()
          : ListenableBuilder(
              listenable: preference,
              builder: (context, _) => body(),
            ),
    );
  }
}

class _FluffyMascotDecorations extends StatefulWidget {
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
    this.playing = true,
    this.moves = false,
    this.hops = false,
    this.beats = false,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;
  final bool moves;
  final bool hops;
  final bool beats;
  final String faceLight;
  final String faceDark;
  final String bottomLight;
  final String bottomDark;
  final Color faceTintLight;
  final Color faceTintDark;
  final Color hillTintLight;
  final Color hillTintDark;

  @override
  State<_FluffyMascotDecorations> createState() =>
      _FluffyMascotDecorationsState();
}

class _FluffyMascotDecorationsState extends State<_FluffyMascotDecorations>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final _phase = ValueNotifier<double>(0);
  var _last = Duration.zero;

  static double _cyclesPerSecond(
    double motion, {
    required bool hops,
    required bool beats,
  }) {
    final slow = beats
        ? 1 / 2.4
        : hops
            ? 1 / 3.6
            : 1 / 6;
    final fast = beats
        ? 1 / 1.15
        : hops
            ? 1 / 1.8
            : 1 / 2.8;
    return slow + (fast - slow) * motion.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _phase.dispose();
    super.dispose();
  }

  void _syncTicker(double motion) {
    if (!widget.moves || motion <= ThemePreference.motionOff) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    _ticker ??= createTicker(_onTick);
    if (!(_ticker?.isActive ?? false)) {
      _last = Duration.zero;
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final motion =
        AppScope.maybeOf(context)?.themePreference.motion ??
            ThemePreference.defaultMotion;
    if (!widget.moves || motion <= ThemePreference.motionOff) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    final last = _last == Duration.zero ? elapsed : _last;
    _last = elapsed;
    final dt = (elapsed - last).inMicroseconds / 1000000;
    if (dt <= 0 || dt > 0.08) return;
    _phase.value = (_phase.value +
            dt *
                _cyclesPerSecond(
                  motion,
                  hops: widget.hops,
                  beats: widget.beats,
                )) %
        1.0;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final preference = AppScope.maybeOf(context)?.themePreference;
    Widget body() {
      final motion = widget.moves
          ? (preference?.motion ?? ThemePreference.defaultMotion)
          : 0.0;
      _syncTicker(motion);
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final span = widget.scaleByWidth
              ? width
              : constraints.biggest.shortestSide;
          final paddingBottom = MediaQuery.paddingOf(context).bottom;
          final faceBottomLift =
              widget.liftForNav ? 66 + paddingBottom : height * 0.04;
          final safe = _LogoSafe(
            screenWidth: width,
            paddingTop: MediaQuery.paddingOf(context).top,
            enabled: !widget.simple,
          );
          final decoration = dark ? widget.faceDark : widget.faceLight;
          final hills = dark ? widget.bottomDark : widget.bottomLight;
          final faceTint = dark ? widget.faceTintDark : widget.faceTintLight;
          final hillTint = dark ? widget.hillTintDark : widget.hillTintLight;
          final hillsHeight = _SkinGround.heightOf(
            width,
            height,
            assetRatio: 600 / 2000,
            maxFraction: 0.32,
          );

          Widget tinted(String asset, Color color,
              {BoxFit fit = BoxFit.contain}) {
            return ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: Image.asset(
                asset,
                fit: fit,
                filterQuality: FilterQuality.medium,
              ),
            );
          }

          Widget face({
            required int index,
            required double t,
            double angle = 0,
          }) {
            Widget child = Opacity(
              opacity: dark ? 0.55 : 0.42,
              child: tinted(decoration, faceTint),
            );
            if (angle != 0) {
              child = Transform.rotate(angle: angle, child: child);
            }
            if (motion <= ThemePreference.motionOff) return child;
            if (widget.beats) {
              final p = (t + index * 0.07) % 1.0;
              double beat(double start, double dur) {
                if (p < start || p > start + dur) return 0;
                return math.sin((p - start) / dur * math.pi);
              }
              final pulse = math.max(beat(0.0, 0.16), beat(0.20, 0.14));
              final scale = 1 + pulse * (0.045 + motion * 0.09);
              return Transform.scale(scale: scale, child: child);
            }
            if (widget.hops) {
              final cycle = (t + index * 0.22) % 1.0;
              final lift = cycle < 0.42
                  ? math.sin(cycle / 0.42 * math.pi)
                  : 0.0;
              final sway = math.sin((t + index * 0.31) * math.pi * 2);
              final amp = 3.0 + motion * 8.0;
              return Transform.translate(
                offset: Offset(sway * amp * 0.12, -lift * amp * 0.95),
                child: Transform.rotate(
                  angle: sway * (0.02 + motion * 0.04),
                  child: child,
                ),
              );
            }
            final wave = math.sin((t + index * 0.18) * math.pi * 2);
            final wave2 = math.cos((t + index * 0.27) * math.pi * 2);
            final amp = 2.5 + motion * 6.0;
            return Transform.translate(
              offset: Offset(wave * amp * 0.3, wave2 * amp * 0.55),
              child: Transform.rotate(
                angle: wave * (0.03 + motion * 0.05),
                child: child,
              ),
            );
          }

          Widget faces(double t) {
            final compact = widget.scaleByWidth || widget.simple;
            return Stack(
              children: compact
                  ? [
                      Positioned(
                        top: height * 0.04,
                        right: width * 0.03,
                        width: math.min(width, height) * 0.22,
                        child: face(index: 0, t: t, angle: 0.12),
                      ),
                      Positioned(
                        left: width * 0.04,
                        bottom: height * 0.08,
                        width: math.min(width, height) * 0.2,
                        child: face(index: 1, t: t, angle: -0.1),
                      ),
                      Positioned(
                        right: width * 0.08,
                        bottom: height * 0.22,
                        width: math.min(width, height) * 0.16,
                        child: face(index: 2, t: t, angle: 0.06),
                      ),
                    ]
                  : [
                      Positioned(
                        top: span * 0.02,
                        right: span * 0.02,
                        width: span * 0.36,
                        child: face(index: 0, t: t, angle: 0.12),
                      ),
                      safe.topLeft(
                        left: span * 0.02,
                        top: span * 0.14,
                        width: span * 0.3,
                        child: face(index: 1, t: t, angle: -0.14),
                      ),
                      Positioned(
                        left: span * 0.04,
                        bottom: faceBottomLift,
                        width: span * 0.32,
                        child: face(index: 2, t: t, angle: 0.08),
                      ),
                      Positioned(
                        right: span * 0.03,
                        bottom: faceBottomLift + span * 0.06,
                        width: span * 0.28,
                        child: face(index: 3, t: t, angle: -0.1),
                      ),
                      Positioned(
                        top: height * 0.32,
                        right: span * 0.06,
                        width: span * 0.3,
                        child: face(index: 4, t: t, angle: 0.06),
                      ),
                    ],
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
                if (motion <= ThemePreference.motionOff)
                  faces(0)
                else
                  RepaintBoundary(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _phase,
                      builder: (context, t, _) => faces(t),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return TickerMode(
      enabled: widget.playing,
      child: preference == null
          ? body()
          : ListenableBuilder(
              listenable: preference,
              builder: (context, _) => body(),
            ),
    );
  }
}

bool _sceneMoving(double motion) => motion > ThemePreference.motionOff;

Widget _sceneShift(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final wave = math.sin((t + index * 0.21) * math.pi * 2);
  final look = math.sin((t * 0.55 + index * 0.4) * math.pi * 2);
  return Transform.rotate(
    alignment: Alignment.bottomCenter,
    angle: wave * (0.035 + motion * 0.05) + look * 0.016,
    child: Transform.scale(
      alignment: Alignment.bottomCenter,
      scaleX: 1 + wave * (0.014 + motion * 0.022),
      scaleY: 1 - wave * (0.008 + motion * 0.012),
      child: child,
    ),
  );
}

Widget _sceneBreathe(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final wave = math.sin((t + index * 0.18) * math.pi * 2);
  final amp = 2.0 + motion * 5.0;
  return Transform.translate(
    offset: Offset(wave * amp * 0.12, wave * amp * 0.45),
    child: child,
  );
}

Widget _sceneSway(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final wave = math.sin((t + index * 0.2) * math.pi * 2);
  final amp = 2.5 + motion * 6.0;
  return Transform.translate(
    offset: Offset(wave * amp * 0.7, wave.abs() * amp * 0.15),
    child: Transform.rotate(
      angle: wave * (0.04 + motion * 0.06),
      child: child,
    ),
  );
}

Widget _sceneFloat(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final wave = math.sin((t + index * 0.17) * math.pi * 2);
  final amp = 2.5 + motion * 7.0;
  return Transform.translate(
    offset: Offset(wave * amp * 0.18, wave * amp * 0.85),
    child: child,
  );
}

Widget _sceneTilt(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final wave = math.sin((t + index * 0.12) * math.pi * 2);
  return Transform.rotate(
    angle: wave * (0.05 + motion * 0.08),
    child: child,
  );
}

Widget _scenePulse(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final wave = math.sin((t + index * 0.1) * math.pi * 2);
  return Transform.scale(
    scale: 1 + wave * (0.03 + motion * 0.05),
    child: child,
  );
}

Widget _sceneBob(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final wave = math.sin((t + index * 0.16) * math.pi * 2);
  final amp = 2.2 + motion * 5.5;
  return Transform.translate(
    offset: Offset(wave * amp * 0.18, -wave.abs() * amp * 0.55),
    child: child,
  );
}

Widget _sceneHop(
  Widget child,
  double motion,
  double t, {
  int index = 0,
}) {
  if (!_sceneMoving(motion)) return child;
  final phase = (t + index * 0.2) % 1;
  final hop = phase < 0.42 ? math.sin(phase / 0.42 * math.pi) : 0.0;
  final rest = 1 - hop;
  final sway = math.sin((t + index * 0.3) * math.pi * 2);
  final amp = 7 + motion * 16;
  final idle = (1.6 + motion * 2.8) * rest;
  return Transform.translate(
    offset: Offset(sway * idle * 0.45, -hop * amp + sway * idle * 0.55),
    child: Transform.rotate(
      angle: sway * rest * (0.035 + motion * 0.045),
      alignment: Alignment.bottomCenter,
      child: Transform.scale(
        scaleX: 1 + rest * 0.03 + sway * rest * 0.02,
        scaleY: 1 - rest * 0.03 - sway * rest * 0.02,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    ),
  );
}

Widget _sceneFall({
  required Widget child,
  required double motion,
  required double t,
  required int index,
  required double width,
  required double height,
  required double size,
  required double restLeft,
  required double restTop,
}) {
  if (!_sceneMoving(motion)) {
    return Positioned(
      left: restLeft,
      top: restTop,
      width: size,
      child: child,
    );
  }
  final phase = (t + index * 0.27) % 1.0;
  final travel = height + size * 2.2;
  final top = -size * 1.1 + travel * phase;
  final sway = math.sin(phase * math.pi * 3 + index * 1.3) * size * 0.4;
  return Positioned(
    left: (restLeft + sway).clamp(-size, width),
    top: top,
    width: size,
    child: child,
  );
}

class _SceneMotion extends StatefulWidget {
  const _SceneMotion({
    required this.playing,
    required this.builder,
    this.fall = false,
  });

  final bool playing;
  final bool fall;
  final Widget Function(BuildContext context, double motion, double t) builder;

  @override
  State<_SceneMotion> createState() => _SceneMotionState();
}

class _SceneMotionState extends State<_SceneMotion>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final _phase = ValueNotifier<double>(0);
  var _last = Duration.zero;

  static double _cyclesPerSecond(double motion, {required bool fall}) {
    final slow = fall ? 1 / 16 : 1 / 6;
    final fast = fall ? 1 / 3.2 : 1 / 2.8;
    return slow + (fast - slow) * motion.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _phase.dispose();
    super.dispose();
  }

  void _syncTicker(double motion) {
    if (!_sceneMoving(motion)) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    _ticker ??= createTicker(_onTick);
    if (!(_ticker?.isActive ?? false)) {
      _last = Duration.zero;
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final motion = AppScope.maybeOf(context)?.themePreference.motion ??
        ThemePreference.defaultMotion;
    if (!_sceneMoving(motion)) {
      _ticker?.stop();
      _last = Duration.zero;
      _phase.value = 0;
      return;
    }
    final last = _last == Duration.zero ? elapsed : _last;
    _last = elapsed;
    final dt = (elapsed - last).inMicroseconds / 1000000;
    if (dt <= 0 || dt > 0.08) return;
    _phase.value =
        (_phase.value + dt * _cyclesPerSecond(motion, fall: widget.fall)) % 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final preference = AppScope.maybeOf(context)?.themePreference;
    Widget body() {
      final motion = preference?.motion ?? ThemePreference.defaultMotion;
      _syncTicker(motion);
      if (!_sceneMoving(motion)) {
        return widget.builder(context, motion, 0);
      }
      return RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: _phase,
          builder: (context, t, _) => widget.builder(context, motion, t),
        ),
      );
    }

    return TickerMode(
      enabled: widget.playing,
      child: preference == null
          ? body()
          : ListenableBuilder(
              listenable: preference,
              builder: (context, _) => body(),
            ),
    );
  }
}

class _SummerBeachDecorations extends StatelessWidget {
  const _SummerBeachDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final span = scaleByWidth
                ? width
                : constraints.biggest.shortestSide;
            final paddingBottom = MediaQuery.paddingOf(context).bottom;
            final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
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
                    child: _sceneSway(sticker(duck), motion, t),
                  ),
                  Positioned(
                    top: span * 0.03,
                    right: span * 0.03,
                    width: span * 0.24,
                    child: _scenePulse(sticker(sun), motion, t),
                  ),
                ],
              ),
            );
          },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      fall: true,
      builder: (context, motion, t) {
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

            Widget flakeAt({
              required int index,
              required double left,
              required double top,
              required double size,
              bool pin = false,
            }) {
              final at = pin
                  ? safe.pin(left: left, top: top, width: size)
                  : (left: left, top: top);
              return _sceneFall(
                child: sticker(flake),
                motion: motion,
                t: t,
                index: index,
                width: width,
                height: height,
                size: size,
                restLeft: at.left,
                restTop: at.top,
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
                    flakeAt(
                      index: 0,
                      left: width - span * 0.2,
                      top: span * 0.02,
                      size: span * 0.16,
                    ),
                    flakeAt(
                      index: 1,
                      left: span * 0.08,
                      top: span * 0.14,
                      size: span * 0.12,
                      pin: true,
                    ),
                    flakeAt(
                      index: 2,
                      left: width - span * 0.32,
                      top: height * 0.26,
                      size: span * 0.14,
                    ),
                    flakeAt(
                      index: 3,
                      left: width * 0.42,
                      top: height * 0.4,
                      size: span * 0.18,
                      pin: true,
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
      },
    );
  }
}

class _SquishyBearDecorations extends StatelessWidget {
  const _SquishyBearDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneBreathe(sticker(bear), motion, t),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                  child: _sceneFloat(sticker(berry), motion, t, index: 0),
                ),
                safe.topLeft(
                  left: span * 0.06,
                  top: span * 0.14,
                  width: span * 0.13,
                  child: _sceneFloat(sticker(berry), motion, t, index: 1),
                ),
                safe.topLeft(
                  left: width * 0.44,
                  top: height * 0.34,
                  width: span * 0.15,
                  child: _sceneFloat(sticker(berry), motion, t, index: 2),
                ),
                safe.topLeft(
                  left: span * 0.1,
                  top: height * 0.5,
                  width: span * 0.12,
                  child: _sceneFloat(sticker(berry), motion, t, index: 3),
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
                child: _sceneShift(sticker(carton), motion, t),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                  child: _sceneFloat(sticker(balloons), motion, t),
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
      },
    );
  }
}

class _RainyDayDecorations extends StatelessWidget {
  const _RainyDayDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
        return LayoutBuilder(
          builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final span = scaleByWidth
            ? width
            : constraints.biggest.shortestSide;
        final paddingBottom = MediaQuery.paddingOf(context).bottom;
        final groundBottom = liftForNav ? 58 + paddingBottom : height * 0.02;
        final puppy = dark
            ? AppSkinAssets.puddlePuppyDark
            : AppSkinAssets.puddlePuppyLight;
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
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: _sceneHop(sticker(puppy), motion, t),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneBob(
                  Image.asset(
                    guitarist,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  motion,
                  t,
                ),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneBreathe(sticker(sheep), motion, t),
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
      },
    );
  }
}

class _CatVillageDecorations extends StatelessWidget {
  const _CatVillageDecorations({
    required this.liftForNav,
    this.scaleByWidth = false,
    this.simple = false,
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneShift(sticker(box), motion, t, index: 0),
              ),
              Positioned(
                right: span * 0.02,
                bottom: groundBottom,
                width: span * 0.34,
                child: _sceneShift(sticker(pile), motion, t, index: 1),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneBreathe(sticker(bakers), motion, t),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneBreathe(sticker(tub), motion, t),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneBreathe(sticker(stall), motion, t),
              ),
            ],
          ),
        );
      },
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
    this.playing = true,
  });

  final bool liftForNav;
  final bool scaleByWidth;
  final bool simple;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _SceneMotion(
      playing: playing,
      builder: (context, motion, t) {
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
                child: _sceneBreathe(sticker(counter), motion, t),
              ),
            ],
          ),
        );
      },
    );
      },
    );
  }
}
