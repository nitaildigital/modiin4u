import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/features/auth/models/user_model.dart';

void main() {
  test('an empty link is none', () {
    expect(normalizeBrokerUrl(''), '');
    expect(normalizeBrokerUrl('   '), '');
  });

  test('a web address is kept, and https:// added to a bare one', () {
    expect(normalizeBrokerUrl('https://www.example.co.il/agent'), 'https://www.example.co.il/agent');
    expect(normalizeBrokerUrl(' http://example.com '), 'http://example.com');
    expect(normalizeBrokerUrl('www.example.co.il'), 'https://www.example.co.il');
    expect(normalizeBrokerUrl('facebook.com/my.office'), 'https://facebook.com/my.office');
  });

  test('anything else is refused', () {
    expect(normalizeBrokerUrl('javascript:alert(1)'), isNull);
    expect(normalizeBrokerUrl('my office'), isNull);
    expect(normalizeBrokerUrl('example'), isNull);
    expect(normalizeBrokerUrl('https://example.com/a b'), isNull);
    expect(normalizeBrokerUrl('https://${'a' * 300}.com'), isNull);
  });
}
