import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Keeps the browser tab title in sync with the current route (web only).
class WebPageTitle extends StatelessWidget {
  const WebPageTitle({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  static const String _brand = 'Bakaloo';
  static const String _homeTitle =
      'Bakaloo - Online Grocery Delivery in 59 Minutes';

  static const List<(String, String)> _titles = <(String, String)>[
    ('/home', _homeTitle),
    ('/splash', _homeTitle),
    ('/off_zone', 'Offers & Deals'),
    ('/super_mall', 'Super Mall'),
    ('/cafe', 'Cafe'),
    ('/categories', 'Shop by Category'),
    ('/search', 'Search Products'),
    ('/product', 'Product Details'),
    ('/products', 'Product Details'),
    ('/cart/checkout', 'Checkout'),
    ('/cart', 'Your Cart'),
    ('/orders/success', 'Order Placed'),
    ('/orders', 'My Orders'),
    ('/auth', 'Login or Sign Up'),
    ('/onboarding', 'Welcome'),
    ('/location-unavailable', 'Location Unavailable'),
    ('/profile/wallet', 'Wallet'),
    ('/profile/wishlist', 'Wishlist'),
    ('/profile/addresses', 'Saved Addresses'),
    ('/profile/notifications', 'Notifications'),
    ('/profile/reviews', 'My Reviews'),
    ('/profile/business-account', 'Business Account'),
    ('/profile/settings', 'Settings'),
    ('/profile', 'My Profile'),
  ];

  @visibleForTesting
  static String titleFor(String path) {
    for (final (String prefix, String title) in _titles) {
      if (path == prefix || path.startsWith('$prefix/')) {
        return title == _homeTitle ? title : '$title | $_brand';
      }
    }
    return path == '/' ? _homeTitle : _brand;
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }
    return ListenableBuilder(
      listenable: router.routeInformationProvider,
      builder: (BuildContext context, Widget? _) {
        final String path = router.routeInformationProvider.value.uri.path;
        return Title(
          title: titleFor(path),
          color: const Color(0xFF663399),
          child: child,
        );
      },
    );
  }
}
