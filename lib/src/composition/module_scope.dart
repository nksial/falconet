import 'package:falconet/src/composition/falconet.dart';
import 'package:falconet/src/composition/module.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart' show ShellRoute;

/// Pushes a GetIt scope for [module] on mount and pops it on dispose.
///
/// Mounted automatically by [Falconet.route] (reusing a feature [ShellRoute]
/// when present). Module authors do not need to reference this widget —
/// define [Module.providers] and [Module.routes] only.
class ModuleScope extends StatefulWidget {
  const ModuleScope({
    required this.module,
    required this.child,
    super.key,
  });

  final Module module;
  final Widget child;

  @override
  State<ModuleScope> createState() => _ModuleScopeState();
}

class _ModuleScopeState extends State<ModuleScope> {
  @override
  void initState() {
    super.initState();
    Falconet.enterModuleScope(widget.module);
  }

  @override
  void dispose() {
    Falconet.exitModuleScope(widget.module);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
