import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_field_bottom_sheets.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_header_bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';
import 'mobile_field_button.dart';

class MobileGridHeader extends StatefulWidget {
  final String viewId;
  final ScrollController anchorScrollController;

  const MobileGridHeader({
    required this.viewId,
    required this.anchorScrollController,
    super.key,
  });

  @override
  State<MobileGridHeader> createState() => _MobileGridHeaderState();
}

class _MobileGridHeaderState extends State<MobileGridHeader> {
  @override
  Widget build(BuildContext context) {
    final fieldController =
        context.read<GridBloc>().databaseController.fieldController;
    return BlocProvider(
      create: (context) {
        return GridHeaderBloc(
          viewId: widget.viewId,
          fieldController: fieldController,
        )..add(const GridHeaderEvent.initial());
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: widget.anchorScrollController,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HSpace(GridSize.leadingHeaderPadding),
            Stack(
              children: [
                Positioned(top: 0, left: 24, right: 24, child: _divider()),
                Positioned(bottom: 0, left: 0, right: 0, child: _divider()),
                SizedBox(
                  height: 50,
                  child: _GridHeader(
                    viewId: widget.viewId,
                    fieldController: fieldController,
                  ),
                ),
              ],
            ),
            const HSpace(20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}

class _GridHeader extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;

  const _GridHeader({
    required this.viewId,
    required this.fieldController,
  });

  @override
  State<_GridHeader> createState() => _GridHeaderState();
}

class _GridHeaderState extends State<_GridHeader> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridHeaderBloc, GridHeaderState>(
      builder: (context, state) {
        final fields = [...state.fields];
        FieldInfo? firstField;
        if (fields.isNotEmpty) {
          firstField = fields.removeAt(0);
        }

        final cells = fields
            .mapIndexed(
              (index, fieldInfo) => MobileFieldButton(
                key: ValueKey(fieldInfo.id),
                index: index,
                viewId: widget.viewId,
                fieldController: widget.fieldController,
                fieldInfo: fieldInfo,
              ),
            )
            .toList();

        return ReorderableListView.builder(
          scrollController: ScrollController(),
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          proxyDecorator: (child, index, anim) => Material(
            color: Colors.transparent,
            child: child,
          ),
          header: firstField != null
              ? MobileFieldButton.first(
                  viewId: widget.viewId,
                  fieldController: widget.fieldController,
                  fieldInfo: firstField,
                )
              : null,
          footer: CreateFieldButton(
            viewId: widget.viewId,
            onFieldCreated: (fieldId) => context
                .read<GridHeaderBloc>()
                .add(GridHeaderEvent.startEditingNewField(fieldId)),
          ),
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex--;
            }
            oldIndex++;
            newIndex++;
            context
                .read<GridHeaderBloc>()
                .add(GridHeaderEvent.moveField(oldIndex, newIndex));
          },
          itemCount: cells.length,
          itemBuilder: (context, index) => cells[index],
        );
      },
    );
  }
}

class CreateFieldButton extends StatefulWidget {
  const CreateFieldButton({
    super.key,
    required this.viewId,
    required this.onFieldCreated,
  });

  final String viewId;
  final void Function(String fieldId) onFieldCreated;

  @override
  State<CreateFieldButton> createState() => _CreateFieldButtonState();
}

class _CreateFieldButtonState extends State<CreateFieldButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: _getDecoration(context),
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        radius: const BorderRadius.only(topRight: Radius.circular(24)),
        text: FlowyText(
          LocaleKeys.grid_field_newProperty.tr(),
          fontSize: 15,
          overflow: TextOverflow.ellipsis,
          color: Theme.of(context).hintColor,
        ),
        hoverColor: AFThemeExtension.of(context).greyHover,
        onTap: () => showCreateFieldBottomSheet(context, widget.viewId),
        leftIconSize: const Size.square(18),
        leftIcon: FlowySvg(
          FlowySvgs.add_s,
          size: const Size.square(18),
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }

  BoxDecoration? _getDecoration(BuildContext context) {
    final borderSide = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 1.0,
    );

    return BoxDecoration(
      borderRadius: const BorderRadiusDirectional.only(
        topEnd: Radius.circular(24),
      ),
      border: BorderDirectional(
        top: borderSide,
        end: borderSide,
      ),
    );
  }
}
