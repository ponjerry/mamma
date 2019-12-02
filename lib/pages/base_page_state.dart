import 'dart:io';

import 'package:mamma/animation/animation_builder.dart';
import 'package:mamma/animation/loading_animator.dart';
import 'package:mamma/common/callback_type.dart';
import 'package:mamma/enums/route_type.dart';
import 'package:mamma/mixins/loading_showable.dart';
import 'package:mamma/utils/app_util.dart';
import 'package:mamma/utils/common_util.dart';
import 'package:mamma/utils/exception_util.dart';
import 'package:mamma/widgets/custom_back_button.dart';
import 'package:mamma/widgets/custom_close_button.dart';
import 'package:mamma/widgets/no_internet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info/package_info.dart';

enum _PageState {
  idle,
  loading,
  noInternet,
}

/// Base state of all pages
abstract class BasePageState<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin, LoadingShowable, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _PageState _pageState = _PageState.loading;
  LoadingAnimator _animator;
  OverlayEntry _versionOverlay;

  ScaffoldState get _scaffoldState => _scaffoldKey.currentState;
  bool get hasNoInternet => _pageState == _PageState.noInternet;
  bool get isLoading => _pageState == _PageState.loading;

  @override
  void setState(fn) {
    /// Override setState function to avoid when the widget is already disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    // Animator should set before super.initState to use animator in build phase.
    if (hasAfterLoadingAnimation) {
      _animator = LoadingAnimator();
      _animator.init(this);
    }
    super.initState();
    // This is the workaround for calling only once just after initState
    Future.microtask(reload);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animator?.dispose();
    _versionOverlay?.remove();
    super.dispose();
  }

  Future<void> showLoadingPage(
      {Function() preloadHandler, Function() postLoadHandler}) async {
    try {
      setState(() {
        _pageState = _PageState.loading;
      });
      if (preloadHandler != null) {
        await preloadHandler();
      }
      setState(() {
        _pageState = _PageState.idle;
      });
    } on SocketException catch (_) {
      setState(() {
        _pageState = _PageState.noInternet;
      });
    } catch (error, stackTrace) {
      report(error, stackTrace);
      // Show no internet view currectly when error occurred.
      setState(() {
        _pageState = _PageState.noInternet;
      });
    } finally {
      if (mounted) {
        _animator
            ?.startAnimation()
            ?.then((_) async => await postLoadHandler(), onError: report);
      }
    }
  }

  @mustCallSuper
  void reload() {
    if (!precondition) {
      navigator.pop();
      return;
    }
    if (preloadListCallback != null || postloadListCallback != null) {
      showLoadingPage(
        preloadHandler: () async {
          if (preloadListCallback != null) {
            await Future.wait(preloadListCallback());
          }
          await onPreload();
        },
        postLoadHandler: () async {
          if (postloadListCallback != null) {
            await Future.wait(postloadListCallback());
          }
          onPostLoad();
        },
      );
    } else if (_pageState != _PageState.idle) {
      onPostLoad();
      setState(() => _pageState = _PageState.idle);
    }
  }

  /// The application is visible and responding to user input.
  ///
  /// This callback function will be called when the application starts its feature again. In iOS, if you double clicked
  /// home button and return back to the application, it will be called. Click app icon from home button, it will be
  /// also triggered.
  @mustCallSuper
  void onResumed() {
    if (hasNoInternet) {
      reload();
    }
  }

  /// The application is in an inactive state and is not receiving user input.
  ///
  /// This callback function will be called when you put the application is not foreground, but it is not necessary to
  /// be in background. In iOS, it will be called when you push home button. It will be also fired when you double
  /// clicked home button.
  void onInactive() {}

  /// The application is not currently visible to the user, not responding to user input, and running in the background.
  ///
  /// This callback function will be called when your application is in background fully. When you click home button,
  /// first onInactive is called, then onPaused will be called.
  void onPaused() {}

  /// The application will be suspended momentarily.
  ///
  /// This callback is called when you terminate the application. On iOS, this state is currently unused.
  void onSuspending() {}

  @override
  @mustCallSuper
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        return onResumed();
      case AppLifecycleState.inactive:
        return onInactive();
      case AppLifecycleState.paused:
        return onPaused();
      case AppLifecycleState.suspending:
        return onSuspending();
    }
    assert(false);
  }

  /// Leading widget builder
  ///
  /// This part is came from [build] function in [AppBar] class which is provided from flutter
  /// library in flutter/packages/flutter/lib/src/material/app_bar.dart.
  ///
  /// Please refer the original class before changing it.
  @mustCallSuper
  Widget buildLeading(BuildContext context) {
    final ScaffoldState scaffold = Scaffold.of(context, nullOk: true);
    final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);
    final bool hasDrawer = scaffold?.hasDrawer ?? false;
    final bool canPop = parentRoute?.canPop ?? false;
    final bool useCloseButton =
        parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;

    if (hasDrawer) {
      return IconButton(
        // Make a new icon for hamburger button before using drawer.
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    } else if (canPop) {
      return useCloseButton
          ? const CustomCloseButton()
          : const CustomBackButton();
    }
    return null;
  }

  /// TitleWidget of the title section
  ///
  /// If you override this, overriding [title] will be ignored
  Widget buildTitleWidget(BuildContext context) {
    return let(title, (title) => Text(title));
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    if (isLoading) {
      return null;
    }
    return AppBar(
      leading: buildLeading(context),
      title: buildTitleWidget(context),
      actions: buildAppBarActions(context),
      centerTitle: true,
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const CircularProgressIndicator();
  }

  Widget buildLoadingWidget(BuildContext context) {
    return Center(
      child: _buildLoadingIndicator(context),
    );
  }

  Widget _buildInnerContents(BuildContext context) {
    if (!precondition) {
      return Container();
    }
    if (hasNoInternet) {
      return buildNoInternetView();
    }
    return buildContents(context);
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return buildLoadingWidget(context);
    }

    Widget current;
    if (_animator != null) {
      current = AnimationBuilder(
        animator: _animator,
        builder: _buildInnerContents,
      );
    } else {
      current = _buildInnerContents(context);
    }
    current = SafeArea(
      child: current,
      minimum: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
    );
    return current;
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    if (hasNoInternet) {
      return null;
    }
    if (isLoading) {
      return null;
    }
    return buildBottomNavigationBar(context);
  }

  Widget buildBottomButton({
    BuildContext context,
    String title,
    Color color,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16.0),
    VoidCallback onPressed,
  }) {
    return Container(
      color: color,
      padding: padding,
      child: RaisedButton(
        child: Text(title),
        onPressed: onPressed,
      ),
    );
  }

  /// If you want to customize scaffold, fix it to support your purpose or override it.
  Scaffold buildScaffold(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: buildFloatingActionButton(context),
    );
  }

  WillPopCallback _getWillPopCallback() {
    assert(
        onWillPopCallback == null || valueCallbackForBackButtonClicked == null,
        'Either "onWillPopCallback" or "valueCallbackForBackButtonClicked" should be set');
    if (onWillPopCallback != null) {
      return onWillPopCallback;
    }
    if (valueCallbackForBackButtonClicked != null) {
      return () async {
        final value = valueCallbackForBackButtonClicked();
        if (value == null) {
          return true;
        }
        navigator.pop(value);
        return false;
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget current = buildScaffold(context);

    let(_getWillPopCallback(), (willPopCallback) {
      current = WillPopScope(
        child: current,
        onWillPop: willPopCallback,
      );
    });
    return current;
  }

  NavigatorState get navigator => Navigator.of(context);

  /// Return typed return value for pushed page
  Future<R> pushPage<R>(RouteType route, {Object arguments}) async {
    return await navigator.pushNamed(toRouteName(route), arguments: arguments)
        as R;
  }

  /// Move to route page and return boolean as a return value
  ///
  /// The routed page may return success flag of the routed page.
  @mustCallSuper
  Future<bool> pushPageAndReturnBool(RouteType route,
      {Object arguments}) async {
    final returnValue = await pushPage(route, arguments: arguments);

    if (!(returnValue is bool)) {
      assert(() {
        throw FlutterError(
            'The type of return value for pushed page should be boolean.\n'
            'Type of the return value is "${returnValue.runtimeType}".');
      }());
      return false;
    }

    return returnValue as bool;
  }

  Future<void> gotoPage(RouteType routeType) {
    return Navigator.of(context)
        .pushNamedAndRemoveUntil(toRouteName(routeType), (_) => false);
  }

  Future<void> report(dynamic error, StackTrace stackTrace) async {
    print('Error will be reported! ($error)');
    // TODO(hyungsun): Report error
  }

  /// Show snackbar on the Scaffold.
  void showSnackBar(SnackBar snackbar) {
    _scaffoldState.showSnackBar(snackbar);
  }

  void showSimpleSnackBar(String text) {
    if (text == null) {
      return;
    }
    showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorSnackBar(String text, dynamic error) {
    showSimpleSnackBar(isInDebugMode ? '$text: $error' : text);
  }

  void showUnknownError(dynamic error, StackTrace stackTrace) {
    showSimpleSnackBar(extractErrorMessage(error));
    report(error, stackTrace);
  }

  Future<void> showVersionOverlay() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      createVersionOverlayEntry(packageInfo);
    } catch (error) {
      // Failed to show version overlay
      print(error);
    }
  }

  // Create version overlay and put it on the top of the page
  void createVersionOverlayEntry(PackageInfo packageInfo) {
    if (context == null) {
      return;
    }
    _versionOverlay?.remove();
    _versionOverlay = OverlayEntry(
      builder: (context) => Positioned(
        right: 10.0,
        top: 0,
        child: SafeArea(
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  height: 14.0,
                  child: Text(
                    'Client: ${packageInfo.version} (${packageInfo.buildNumber})',
                    style: Theme.of(context).textTheme.overline,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_versionOverlay);
  }

  Widget buildRefreshIndicator(
    BuildContext context,
    Widget child,
    VoidCallback onRefresh, {
    bool needScrollWidget = false,
  }) {
    Widget current = child;
    if (needScrollWidget) {
      // Use Scroll view to use refresh indicator
      current = SingleChildScrollView(
        child: current,
        physics: const AlwaysScrollableScrollPhysics(),
      );
    }
    // Expand width and height
    current = Container(
      height: double.infinity,
      width: double.infinity,
      child: current,
    );
    current = RefreshIndicator(
      child: current,
      onRefresh: () async => onRefresh(),
    );
    return current;
  }

  // Precondition of this page. If precondition is not met, pop this page
  bool get precondition => true;

  /// Title of the title section
  String get title => '';

  // Indicate to show loading animation (e.g., fade-in)
  bool get hasAfterLoadingAnimation => true;

  /// When back button clicked, set return value.
  ValueCallback get valueCallbackForBackButtonClicked => null;

  /// It is called when pop. If returns false, the pop wil be ignored; otherwise, pop will be executed.
  WillPopCallback get onWillPopCallback => null;

  /// Body of the Scaffold
  Widget buildContents(BuildContext context);

  /// Bottom navigation bar builder
  Widget buildBottomNavigationBar(BuildContext context) => null;

  /// AppBar actions
  List<Widget> buildAppBarActions(BuildContext context) => null;

  /// Floating action button widget
  Widget buildFloatingActionButton(BuildContext context) => null;

  /// No Internet view builder
  Widget buildNoInternetView() => NoInternetView(onRetryPressed: reload);

  /// Preload futures. Override this function if you want preload some functions
  List<Future> Function() get preloadListCallback => null;

  /// onLoad function when there is preloadList
  Future<void> onPreload() async {}

  /// Postload futures. Override this function if you want preload some functions
  List<Future> Function() get postloadListCallback => null;

  /// onLoad function when there is postLoadCallback
  void onPostLoad() {}
}
