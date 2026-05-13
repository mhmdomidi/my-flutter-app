import 'package:tuple/tuple.dart';

class AppIcons {
  static const logo = 'assets/svg/logo.svg';

  // bottom navigation - start

  static const bottomNavHome = 'assets/svg/bottom_nav/home.svg';
  static const bottomNavHomeActive = 'assets/svg/bottom_nav/home_active.svg';

  static const bottomNavSearch = 'assets/svg/bottom_nav/search.svg';
  static const bottomNavSearchActive = 'assets/svg/bottom_nav/search_active.svg';

  static const bottomNavCreatePost = 'assets/svg/bottom_nav/create_post.svg';

  static const bottomNavFavorite = 'assets/svg/bottom_nav/favorite.svg';
  static const bottomNavFavoriteActive = 'assets/svg/bottom_nav/favorite_active.svg';

  static const bottomNavAccount = 'assets/svg/bottom_nav/account.svg';
  static const bottomNavAccountActive = 'assets/svg/bottom_nav/account_active.svg';

  static const bottomTabIcons = [
    Tuple2(bottomNavHome, bottomNavHomeActive),
    Tuple2(bottomNavSearch, bottomNavSearchActive),
    Tuple2(bottomNavCreatePost, bottomNavCreatePost),
    Tuple2(bottomNavFavorite, bottomNavFavoriteActive),
    Tuple2(bottomNavAccount, bottomNavAccountActive),
  ];
}
