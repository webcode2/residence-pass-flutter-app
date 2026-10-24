import 'package:estate/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Host display label preserves backend role compatibility', () {
    final host =
        UserModel(id: 'host', email: 'host@example.com', roles: ['landlord']);
    expect(host.roleTitle, 'Host');
    expect(host.isLandlord, isTrue);
    expect(host.toJson()['roles'], ['landlord']);
    final dualRole = UserModel(
        id: 'host', email: 'host@example.com', roles: ['landlord', 'resident']);
    expect(dualRole.roleTitle, 'Resident • Host');
  });
}
