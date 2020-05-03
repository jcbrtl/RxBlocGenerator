// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: RxBlocGeneratorForAnnotation
// **************************************************************************

part of 'news_bloc.dart';

abstract class NewsBlocType extends RxBlocTypeBase {
  NewsBlocEvents get events;

  NewsBlocStates get states;
}

abstract class $NewsBloc extends RxBlocBase
    implements NewsBlocEvents, NewsBlocStates, NewsBlocType {
  ///region Events

  ///region fetch

  final _$fetchEvent = PublishSubject<void>();
  @override
  void fetch() => _$fetchEvent.add(null);

  ///endregion fetch

  ///region test

  final _$testEvent = PublishSubject<_TestEventArgs>();
  @override
  void test(int id, {String name: 'name', bool shouldBroadcast: false}) =>
      _$testEvent.add(_TestEventArgs(
        id: id,
        name: name,
        shouldBroadcast: shouldBroadcast,
      ));

  ///endregion test

  ///endregion Events

  ///region States

  ///region news
  Stream<List<News>> _newsState;

  @override
  Stream<List<News>> get news => _newsState ??= _mapToNewsState();

  Stream<List<News>> _mapToNewsState();

  ///endregion news

  ///endregion States

  ///region Type

  @override
  NewsBlocEvents get events => this;

  @override
  NewsBlocStates get states => this;

  ///endregion Type

  void dispose() {
    _$fetchEvent.close();
    _$testEvent.close();
    super.dispose();
  }
}

/// region Argument classes

/// region _TestEventArgs class

class _TestEventArgs {
  final int id;
  final String name;
  final bool shouldBroadcast;

  const _TestEventArgs({
    this.id,
    this.name,
    this.shouldBroadcast,
  });
}

/// endregion _TestEventArgs class

/// endregion Argument classes
