import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/friends/data/friends_service.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';

class _SlowFriendsService extends Fake implements FriendsService {
  /// Holds every request until completed, as a slow backend would.
  final reply = Completer<void>();
  final calls = <String>[];

  Future<void> _request(String call) async {
    calls.add(call);
    await reply.future;
  }

  @override
  Future<void> sendInvite(String username) => _request('send $username');

  @override
  Future<void> acceptInvite(String username) => _request('accept $username');

  @override
  Future<void> deleteRelationship(String username) =>
      _request('delete $username');
}

class _NoAvatars extends Fake implements ProfileService {
  @override
  Future<String?> getAvatarUrl(String username) async => null;
}

class _SlowAvatars extends Fake implements ProfileService {
  final reply = Completer<void>();

  @override
  Future<String?> getAvatarUrl(String username) async {
    await reply.future;
    return 'https://avatars/$username';
  }
}

void main() {
  late _SlowFriendsService service;
  late ProviderContainer container;

  setUp(() {
    service = _SlowFriendsService();
    container = ProviderContainer(
      overrides: [
        friendsServiceProvider.overrideWithValue(service),
        profileServiceProvider.overrideWithValue(_NoAvatars()),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'a second tap on a person waiting for the backend sends nothing',
    () async {
      final notifier = container.read(friendsProvider.notifier);

      final first = notifier.acceptInvite('ola');
      await notifier.acceptInvite('ola');
      await notifier.deleteRelationship('ola');
      await notifier.sendInvite('ola');

      expect(service.calls, ['accept ola']);
      service.reply.complete();
      await first;
    },
  );

  test('actions on different people are sent at the same time', () async {
    final notifier = container.read(friendsProvider.notifier);

    final first = notifier.acceptInvite('ola');
    final second = notifier.deleteRelationship('kuba');

    expect(service.calls, ['accept ola', 'delete kuba']);
    service.reply.complete();
    await Future.wait([first, second]);
  });

  test('the person can be acted on again once the backend answered', () async {
    final notifier = container.read(friendsProvider.notifier);
    service.reply.complete();

    await notifier.acceptInvite('ola');
    await notifier.deleteRelationship('ola');

    expect(service.calls, ['accept ola', 'delete ola']);
  });

  group('while the avatar of a new row is still loading', () {
    late _SlowAvatars avatars;

    setUp(() {
      avatars = _SlowAvatars();
      container = ProviderContainer(
        overrides: [
          friendsServiceProvider.overrideWithValue(service),
          profileServiceProvider.overrideWithValue(avatars),
        ],
      );
      addTearDown(container.dispose);
      service.reply.complete();
    });

    List<String> sent() => [
      for (final invite in container.read(friendsProvider).sentInvites)
        invite.username,
    ];

    test('a just-sent invite can be undone', () async {
      final notifier = container.read(friendsProvider.notifier);

      await notifier.sendInvite('ola');
      expect(sent(), ['ola']);
      await notifier.deleteRelationship('ola');

      expect(service.calls, ['send ola', 'delete ola']);
      expect(sent(), isEmpty);
      avatars.reply.complete();
      await pumpEventQueue();
      expect(sent(), isEmpty);
    });

    test('a just-accepted friend can be removed', () async {
      final notifier = container.read(friendsProvider.notifier);

      await notifier.acceptInvite('ola');
      await notifier.deleteRelationship('ola');

      expect(service.calls, ['accept ola', 'delete ola']);
      expect(container.read(friendsProvider).friends, isEmpty);
      avatars.reply.complete();
      await pumpEventQueue();
      expect(container.read(friendsProvider).friends, isEmpty);
    });

    test('the avatar is filled in once it arrives', () async {
      final notifier = container.read(friendsProvider.notifier);

      await notifier.sendInvite('ola');
      avatars.reply.complete();
      await pumpEventQueue();

      expect(
        container.read(friendsProvider).sentInvites.single.avatarUrl,
        'https://avatars/ola',
      );
    });
  });
}
