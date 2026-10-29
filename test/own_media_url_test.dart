import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bakaloo_flutter_app/core/constants/api_constants.dart';

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'BASE_URL=https://api.bakaloo.in/api/v1\nSOCKET_URL=https://api.bakaloo.in'));

  const host = 'https://media.bakaloo.in';
  const id = 'grocery-app/products/abc123';

  group('own media server sizes', () {
    test('picks the smallest uncropped bucket for width x dpr 2', () {
      // listProduct 320 dp -> 640 px
      expect(ApiConstants.optimizeOwnMediaUrl('$host/master/$id.webp', width: 320), '$host/w640/$id.webp');
      // homeProduct 132 dp -> 264 px
      expect(ApiConstants.optimizeOwnMediaUrl('$host/w640/$id.webp', width: 132), '$host/w320/$id.webp');
      // cartThumb 80 dp -> 160 px
      expect(ApiConstants.optimizeOwnMediaUrl('$host/master/$id.webp', width: 80), '$host/w160/$id.webp');
      // detailGallery 520 dp -> 1040 px
      expect(ApiConstants.optimizeOwnMediaUrl('$host/master/$id.webp', width: 520), '$host/w1280/$id.webp');
    });

    test('very wide spots fall back to the master', () {
      expect(ApiConstants.optimizeOwnMediaUrl('$host/w640/$id.webp', width: 1080), '$host/master/$id.webp');
    });

    test('never touches Cloudinary, private, raw or WhatsApp URLs', () {
      expect(ApiConstants.optimizeOwnMediaUrl('https://res.cloudinary.com/x/image/upload/v1/a.jpg', width: 320), isNull);
      expect(ApiConstants.optimizeOwnMediaUrl('$host/private/$id.webp', width: 320), isNull);
      expect(ApiConstants.optimizeOwnMediaUrl('$host/raw/grocery-app/lottie/a.json', width: 320), isNull);
      expect(ApiConstants.optimizeOwnMediaUrl('$host/wa-jpeg/$id.jpg', width: 320), isNull);
      expect(ApiConstants.optimizeOwnMediaUrl('https://other.example/master/$id.webp', width: 320), isNull);
    });

    test('flows through optimizedMedia for every screen profile', () {
      final list = ApiConstants.optimizedMedia('$host/master/$id.webp', profile: CustomerImageProfile.listProduct);
      expect(list.url, '$host/w640/$id.webp');
      final detail = ApiConstants.optimizedMedia('$host/master/$id.webp', profile: CustomerImageProfile.detailGallery);
      expect(detail.url, '$host/w1280/$id.webp');
      final cart = ApiConstants.optimizedMedia('$host/master/$id.webp', profile: CustomerImageProfile.cartThumb);
      expect(cart.url, '$host/w160/$id.webp');
      final banner = ApiConstants.optimizedMedia('$host/master/$id.webp', profile: CustomerImageProfile.banner);
      expect(banner.url, '$host/master/$id.webp'); // 1080 dp x2 = 2160 px: beyond the largest bucket
    });

    test('Cloudinary URLs still get the old transforms (old data keeps working)', () {
      final out = ApiConstants.optimizeCloudinaryUrl(
        'https://res.cloudinary.com/da7zjvpey/image/upload/v1/grocery-app/products/x.jpg',
        width: 320,
      );
      expect(out, contains('w_320'));
    });
  });
}
