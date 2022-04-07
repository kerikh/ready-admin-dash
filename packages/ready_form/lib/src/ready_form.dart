import 'package:flutter/material.dart';

import 'circular_reveal.dart';
import 'config.dart';
import 'keyboard_actions.dart';

typedef OnPostDataCallBack = Future<dynamic> Function();

abstract class ReadyFormState {
  bool validate();
  Future<bool> onSubmit();
  bool get submitting;
  List<FormFieldState> invalidFields();
}

/// Form key to allow accessing [validate] [onSubmit] [invalidFields] methods
class ReadyFormKey extends GlobalKey<_ReadyFormState>
    implements ReadyFormState {
  final String id;
  const ReadyFormKey(this.id) : super.constructor();
  @override
  int get hashCode => identityHashCode(id);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ReadyFormKey && identical(other.id, id);
  }

  /// manually validate form
  @override
  bool validate() => currentState!.validate();

  /// manually submit form
  @override
  Future<bool> onSubmit() => currentState!.onSubmit();

  /// detect if form is now submitting
  @override
  bool get submitting => currentState?.submitting ?? false;

  /// get invalid fields in the current form
  @override
  List<FormFieldState> invalidFields() => currentState?.invalidFields() ?? [];
}

class ReadyForm extends StatefulWidget {
  /// called when ever  form is posted
  final OnPostDataCallBack onPostData;
  final Widget child;

  /// whether if reveal effect will be played or not, disabled by default
  final RevealConfig revealConfig;

  /// title for the  cancel dialog
  final Widget? cancelRequestTitle;

  /// content for the  cancel dialog
  final Widget? cancelRequestContent;

  /// disable taping and editing form fields while submitting defaults to [false]
  final bool? disableEditingOnSubmit;

  /// override yes button
  final Widget? yes;

  /// override no button
  final Widget? no;

  /// if specified will show a dialog when user try to pop and the form is [submitting]
  final VoidCallback? onCancelRequest;

  /// [Form.autovalidateMode]
  final AutovalidateMode? autovalidateMode;

  /// if [true] then it will add keyboard actions , enabled by default
  final KeyBoardActionConfig keyBoardActionConfig;
  const ReadyForm({
    ReadyFormKey? key,
    required this.onPostData,
    required this.child,
    this.revealConfig = const RevealConfig(),
    this.onCancelRequest,
    this.cancelRequestTitle,
    this.cancelRequestContent,
    this.disableEditingOnSubmit,
    this.yes,
    this.autovalidateMode,
    this.keyBoardActionConfig = const KeyBoardActionConfig(),
    this.no,
  }) : super(key: key);

  factory ReadyForm.builder({
    ReadyFormKey? key,
    required OnPostDataCallBack onPostData,
    required Widget Function(BuildContext context, bool submitting) builder,
    RevealConfig revealConfig = const RevealConfig(),
    Widget? cancelRequestTitle,
    Widget? cancelRequestContent,
    Widget? yes,
    Widget? no,
    bool? disableEditingOnSubmit,
    KeyBoardActionConfig keyBoardActionConfig = const KeyBoardActionConfig(),
  }) =>
      ReadyForm(
        key: key,
        revealConfig: revealConfig,
        cancelRequestContent: cancelRequestContent,
        cancelRequestTitle: cancelRequestTitle,
        yes: yes,
        disableEditingOnSubmit: false,
        no: no,
        keyBoardActionConfig: keyBoardActionConfig,
        onPostData: onPostData,
        child: FormSubmitListener(
          builder: (BuildContext context, bool submitting) {
            return builder(context, submitting);
          },
        ),
      );

  static ReadyFormState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ReadyFormState>();
  static _ReadyFormState? _of(BuildContext context) =>
      context.findAncestorStateOfType<_ReadyFormState>();

  static Set<_ReadyFormState> listOf(BuildContext context) {
    return FocusScope.of(context)
        .children
        .map((e) => e.context == null ? null : ReadyForm.of(e.context!))
        .whereType<_ReadyFormState>()
        .toSet();
  }

  @override
  _ReadyFormState createState() => _ReadyFormState();
}

class _ReadyFormState extends State<ReadyForm> implements ReadyFormState {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  CircularRevealController? controller;
  ReadyFormConfig? get config => ReadyFormConfig.of(context);
  final ValueNotifier<bool> _submitting = ValueNotifier<bool>(false);
  @override
  bool get submitting => _submitting.value;
  @override
  bool validate() {
    return formKey.currentState!.validate();
  }

  bool get _disableEditingOnSubmit =>
      widget.disableEditingOnSubmit ?? config?.disableEditingOnSubmit ?? false;

  @override
  List<FormFieldState> invalidFields() {
    if (formKey.currentContext == null) return [];
    return FocusScope.of(formKey.currentContext!)
        .children
        .map((element) {
          if (element.context == null) return null;
          var field =
              element.context!.findAncestorStateOfType<FormFieldState>();
          if (field == null || field.isValid) return null;
          return field;
        })
        .whereType<FormFieldState>()
        .toList();
  }

  Future _goToElement(FormFieldState field) async {
    var scope = FocusScope.of(field.context);
    if (scope.hasFocus) {
      var focus = scope.children.firstOrDefault(
        (element) =>
            element.context?.findAncestorStateOfType<FormFieldState>() == field,
      );
      if (focus != null && focus != scope.focusedChild) {
        scope.requestFocus(focus);
        return;
      }
    }

    await Scrollable.ensureVisible(
      field.context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInCubic,
      alignment: 1.0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  Future<bool> onSubmit() async {
    if (submitting) return false;
    if (validate()) {
      formKey.currentState!.save();
      await _validationSuccess();
      return true;
    } else {
      var items = invalidFields();
      if (items.isNotEmpty) {
        await _goToElement(items.first);
      }
      return false;
    }
  }

  Future<dynamic> _validationSuccess() async {
    var currentFocus = FocusScope.of(formKey.currentContext!);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    setState(() {
      _submitting.value = true;
    });
    try {
      if (_disableEditingOnSubmit) FocusScope.of(context).unfocus();
      var result = await widget.onPostData();
      setState(() {
        _submitting.value = false;
      });
      if (controller != null) {
        await controller!.reveal().then((value) async {
          await Future.delayed(const Duration(milliseconds: 300));
          await controller?.unReveal();
        });
      }

      return result;
    } catch (e) {
      setState(() {
        _submitting.value = false;
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    var reveal = config?.revealConfig.copyWith(widget.revealConfig) ??
        widget.revealConfig;
    if (reveal.enabled == true) {
      return CircularReveal(
        revealColor: reveal.color,
        build: (CircularRevealController ctrl) {
          controller = ctrl;
          return _build(context);
        },
      );
    } else {
      return _build(context);
    }
  }

  Widget _build(BuildContext context) {
    var keyBoardActionConfig =
        config?.keyBoardActionConfig.copyWith(widget.keyBoardActionConfig) ??
            widget.keyBoardActionConfig;
    if (keyBoardActionConfig.enabled != false) {
      return KeyboardActions(
        policy: keyBoardActionConfig.policy,
        child: _buildForm(context),
      );
    } else {
      return _buildForm(context);
    }
  }

  Widget _buildForm(BuildContext context) {
    return AbsorbPointer(
      absorbing: _disableEditingOnSubmit && _submitting.value,
      child: Form(
        key: formKey,
        onWillPop: () async {
          if (!submitting || widget.onCancelRequest == null) return true;

          var res = await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: widget.cancelRequestTitle ??
                      config?.cancelRequestTitle ??
                      const Text("Cancel request"),
                  content: widget.cancelRequestContent ??
                      config?.cancelRequestContent ??
                      const Text(
                          "Do you want to leave and cancel the current action?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        widget.onCancelRequest?.call();
                        Navigator.of(context).pop("yes");
                      },
                      child: widget.yes ?? config?.yes ?? const Text("Yes"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop("no");
                      },
                      style: TextButton.styleFrom(
                          primary: Theme.of(context).errorColor),
                      child: widget.no ?? config?.no ?? const Text("No"),
                    )
                  ],
                );
              });
          return res == "yes";
        },
        autovalidateMode: widget.autovalidateMode,
        child: widget.child,
      ),
    );
  }
}

extension IterableExtensions<T> on Iterable<T> {
  /// get the first item that match expression or null if not any
  T? firstOrDefault([bool Function(T element)? test]) {
    var filtered = test == null ? this : where(test);
    if (filtered.isNotEmpty) {
      return filtered.first;
    } else {
      return null;
    }
  }
}

class FormSubmitListener extends StatelessWidget {
  final Widget Function(BuildContext context, bool submitting) builder;
  const FormSubmitListener({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ReadyForm._of(context)!._submitting,
      builder: (BuildContext ctx, bool v, c) => builder(ctx, v),
    );
  }
}
