import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

abstract class RefreshingConsumerState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> with RouteAware {
  ModalRoute<dynamic>? _route;
  bool _firstTimeVisibleCalled = false;

  /// Chiamato quando la schermata diventa VISIBILE:
  /// - prima volta che ci entri (push)
  /// - quando torni da una schermata sopra (pop)
  void onRouteVisible();

  /// (opzionale) chiamato quando vai avanti e la schermata viene COPERTA
  void onRouteHidden() {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route == null) return;

    if (_route != route) {
      if (_route != null) routeObserver.unsubscribe(this);
      _route = route;
      routeObserver.subscribe(this, route!);
    }

    // Garantisce la chiamata almeno una volta anche se didPush non arriva
    if (!_firstTimeVisibleCalled) {
      _firstTimeVisibleCalled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onRouteVisible();
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    onRouteVisible();
  }

  @override
  void didPopNext() {
    onRouteVisible();
  }

  @override
  void didPushNext() {
    onRouteHidden();
  }
}
