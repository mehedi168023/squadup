import 'package:flutter_test/flutter_test.dart';
import 'package:squadup/app/core/app_constants.dart';

void main() {
  test('taka formats amounts with the Taka symbol and thousands separators', () {
    expect(taka(0), '৳0');
    expect(taka(1250), '৳1,250');
    expect(taka(1000000), '৳1,000,000');
  });
}
