import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DgtAppBar {
  DgtAppBar._();

  static const _logo =
      'assets/images/logo-dgt-digitaltransformation_fundo_escuro.png';

  static Widget _logoWidget({double h = 20}) =>
      Image.asset(_logo, height: h, fit: BoxFit.contain);

  // AppBar padrão para telas principais e de detalhe simples
  static AppBar simple({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) =>
      AppBar(
        backgroundColor: AppColors.darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _logoWidget(),
            const SizedBox(width: 10),
            subtitle == null
                ? Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white60)),
                    ],
                  ),
          ],
        ),
        actions: actions,
        bottom: bottom,
      );

  // AppBar de detalhe com 3 linhas (tipo / pessoa / contexto)
  static AppBar detail({
    required String typeLabel,
    String? personLabel,
    required String contextLine,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) =>
      AppBar(
        backgroundColor: AppColors.darkGray,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 68,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _logoWidget(h: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  if (personLabel != null && personLabel.isNotEmpty)
                    Text(personLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  Text(contextLine,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
        actions: actions,
        bottom: bottom,
      );
}
