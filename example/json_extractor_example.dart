import 'package:json_extractor/json_extractor.dart';

/// An imaginable server response with a list of service users.
const serviceUsersJson = {
  'users': [
    {
      'user': {
        'id': 1,
        'name': 'Kathryn',
        'post_ids': [1, 12, 14, 20, 31],
        'is_admin': true
      }
    },
    {
      'user': {
        'id': 2,
        'name': 'Dmytro',
        'post_ids': [2, 17, 21],
        'is_admin': false
      }
    }
    // ... probably more users
  ]
};

/// Returns a list of ids of all users in the given JSON.
///
/// If no users are present in the [usersJson], returns an empty list.
///
List<int> userIds(dynamic usersJson) {
  const extractor = JsonExtractor({'ids': 'users.user.id'});

  final extracted = extractor.process(usersJson);

  return extracted['ids']?.cast<int>() ?? [];
}

/// Returns a list of user names in the given JSON.
///
/// If no users are present in the [usersJson], returns an empty list.
///
List<String> userNames(dynamic usersJson) {
  const extractor = JsonExtractor({'names': 'users.user.name'});

  final extracted = extractor.process(usersJson);

  return extracted['names']?.cast<String>() ?? [];
}

/// Returns a list of users who are admins in the given JSON.
List<Map> admins(dynamic usersJson) {
  const extractor = JsonExtractor({'users': 'users.user'});

  final extracted = extractor.process(usersJson);

  return extracted['users']
      .where((userMap) => userMap['is_admin'] as bool)
      .cast<Map>()
      .toList();
}

void main() {
  final adminsList = admins(serviceUsersJson);
  final userNamesList = userNames(serviceUsersJson);
  final userIdsList = userIds(serviceUsersJson);

  print('Admins: $adminsList');
  print('User names: $userNamesList');
  print('User ids: $userIdsList');
}
