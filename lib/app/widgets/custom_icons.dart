import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Collection d'icônes SVG personnalisées pour Weylo
class CustomIcons {
  /// Icône Chat - Conversation privée
  static Widget chat({
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M20 12.2c0 4.3-3.8 7.8-8.5 7.8-1.1 0-2.2-.2-3.2-.6l-3.4 1.4c-.6.3-1.3-.3-1.1-.9l1-3.4A7.4 7.4 0 0 1 3.5 12.2C3.5 7.9 7.3 4.4 12 4.4s8 3.5 8 7.8Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9.2 12.1h.01M12 12.1h.01M14.8 12.1h.01"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round"/>
  <path d="M17.2 6.2l.5 1.1 1.1.5-1.1.5-.5 1.1-.5-1.1-1.1-.5 1.1-.5.5-1.1Z"
        fill="currentColor" opacity=".9"/>
</svg>''',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Icône Anonyme - Messages anonymes
  static Widget anonyme({
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M4.6 10.2c0-2.1 1.4-3.9 3.4-4.4l1.8-.4a10.5 10.5 0 0 1 4.4 0l1.8.4c2 .5 3.4 2.3 3.4 4.4v2c0 4.4-3.3 7.9-7.8 7.9s-7.8-3.5-7.8-7.9v-2Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.1 11.1c.9-.7 2-.7 2.9 0M13 11.1c.9-.7 2-.7 2.9 0"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round"/>
  <path d="M12 13.5c-2.1 0-3.6 1.6-3.6 3.6 0 2 1.5 3.5 3.6 3.5s3.6-1.5 3.6-3.5c0-2-1.5-3.6-3.6-3.6Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round" opacity=".85"/>
  <path d="M10.2 17.1c.2-1.1 1-1.9 1.8-1.9s1.6.8 1.8 1.9M10.4 18.4c.4.6 1 .9 1.6.9s1.2-.3 1.6-.9"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".85"/>
</svg>''',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Icône Groupe - Groupes de discussion
  static Widget groupe({
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M12 5.4a3.2 3.2 0 1 0 0 6.4 3.2 3.2 0 0 0 0-6.4Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M6.2 19.2c1.1-2.8 3.2-4.3 5.8-4.3s4.7 1.5 5.8 4.3"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M4.8 12.3c.9-3.7 4-6.4 7.8-6.4s6.9 2.7 7.8 6.4"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".75"/>
  <path d="M5.4 13.4h.01M18.6 13.4h.01"
        stroke="currentColor" stroke-width="4.2" stroke-linecap="round" opacity=".85"/>
</svg>''',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Icône Feed - Fil d'actualité
  static Widget feed({
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M7 6.3h10c1.7 0 3 1.3 3 3v7.8c0 1.7-1.3 3-3 3H7c-1.7 0-3-1.3-3-3V9.3c0-1.7 1.3-3 3-3Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.2 10.2h7.6M8.2 13.1h6.2M8.2 16h5"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".9"/>
  <path d="M17.7 10.1c.8.9.8 1.8.2 2.6-.5.6-1.3 1-2 1 .3-1.1.1-2-.7-2.8.7-.2 1.6-.4 2.5-.8Z"
        fill="currentColor" opacity=".9"/>
</svg>''',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Icône Profile - Profil utilisateur
  static Widget profile({
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M12 2.8 19.2 7v10L12 21.2 4.8 17V7L12 2.8Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M12 7.6a3 3 0 1 0 0 6 3 3 0 0 0 0-6Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M7.6 18c.8-1.9 2.4-3 4.4-3s3.6 1.1 4.4 3"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".9"/>
</svg>''',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Icône Notifications - Notifications
  static Widget notifications({
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M18 10.1c0-3.3-2.3-5.7-6-5.7s-6 2.4-6 5.7V13c0 .9-.3 1.8-.8 2.6l-.7 1.1h15l-.7-1.1c-.5-.8-.8-1.7-.8-2.6v-2.9Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9.6 19a2.4 2.4 0 0 0 4.8 0"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round"/>
  <path d="M18.9 5.5l.5 1 1 .5-1 .5-.5 1-.5-1-1-.5 1-.5.5-1Z"
        fill="currentColor" opacity=".95"/>
  <path d="M20.3 8.9c.2-.5.3-1.1.3-1.7"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".75"/>
</svg>''',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Icône Search - Recherche
  static Widget search({
    double size = 24,
    Color? color,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M10.9 18.3a7.4 7.4 0 1 0 0-14.8 7.4 7.4 0 0 0 0 14.8Z"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M20 20l-3.3-3.3"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M10.9 7.6v1.2M7.9 10.6h1.2"
        stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".85"/>
  <path d="M13.7 9.2l-1.1 3.2-3.2 1.1 1.1-3.2 3.2-1.1Z"
        fill="currentColor" opacity=".9"/>
</svg>''',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  /// Icône Flame - Flammes/Streak
  static Widget flame({
    double size = 24,
    Color? color,
  }) {
    return Icon(
      Icons.local_fire_department_rounded,
      size: size,
      color: color,
    );
  }
}
