import 'package:flutter/widgets.dart';
import 'package:longpress_popup/src/animated_stack.dart';

/// Manages the children of an [AnimatedStack].
///
/// The [insert] and [removeAt] methods apply to both the internal list and
/// the animated list that belongs to [animatedStackKey].
///
class AnimatedStackManager<E> {
  static const Duration _kDuration = Duration(milliseconds: 300);

  final Duration duration;

  AnimatedStackManager({
    required this.animatedStackKey,
    required this.removedItemBuilder,
    Iterable<E>? initialItems,
    Duration? duration,
  })  : _items = List<E>.from(initialItems ?? <E>[]),
        duration = duration ?? _kDuration;

  final GlobalKey<AnimatedStackState> animatedStackKey;
  final RemovedItemBuilder<E> removedItemBuilder;
  final List<E> _items;

  AnimatedStackState? get _animatedStack => animatedStackKey.currentState;

  void insert(int index, E item, {Duration? duration}) {
    _items.insert(index, item);
    _animatedStack!.insertItem(index, duration: duration ?? this.duration);
  }

  E removeAt(int index, {Duration? duration}) {
    final E removedItem = _items.removeAt(index);
    if (removedItem != null) {
      _animatedStack!.removeItem(
        index,
        (BuildContext context, Animation<double> animation) {
          return removedItemBuilder(removedItem, context, animation);
        },
        duration: duration ?? this.duration,
      );
    }
    return removedItem;
  }

  void clear({Duration? duration}) {
    for (var i = 0; i <= _items.length - 1; i++) {
      final item = _items[i];
      _animatedStack!.removeItem(
        0,
        (BuildContext context, Animation<double> animation) {
          return removedItemBuilder(item, context, animation);
        },
        duration: duration ?? this.duration,
      );
    }
    _items.clear();
  }

  void removeWhere(bool Function(E) test, {Duration? duration}) {
    var offsetDueToRemovals = 0;
    final itemsLength = _items.length;

    for (var i = 0; i <= itemsLength - 1; i++) {
      final removalIndex = i - offsetDueToRemovals;
      final item = _items[removalIndex];
      if (!test(item)) continue;

      _items.removeAt(removalIndex);
      _animatedStack!.removeItem(
        removalIndex,
        (BuildContext context, Animation<double> animation) {
          return removedItemBuilder(item, context, animation);
        },
        duration: duration ?? this.duration,
      );

      offsetDueToRemovals++;
    }
  }

  bool contains(E item) => _items.contains(item);

  int get length => _items.length;

  E operator [](int index) => _items[index];

  int indexOf(E item) => _items.indexOf(item);

  bool any(bool Function(E) test) => _items.any(test);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;
}

typedef RemovedItemBuilder<E> = Widget Function(
  E item,
  BuildContext context,
  Animation<double> animation,
);
