import 'package:flutter/material.dart';

/// A utility to map string keys to constant IconData.
/// This allows Flutter's icon tree-shaker to work correctly in release builds.
class IconMapper {
  static const Map<String, IconData> _iconMap = {
    'notifications': Icons.notifications,
    'work': Icons.work,
    'photo': Icons.photo,
    'school': Icons.school,
    'emoji_events': Icons.emoji_events,
    'computer': Icons.computer,
    'layers': Icons.layers,
    'calendar_month': Icons.calendar_month,
    'picture_as_pdf': Icons.picture_as_pdf,
    'download': Icons.download,
    'person': Icons.person,
    'camera_alt': Icons.camera_alt,
    'phone': Icons.phone,
    'email': Icons.email,
    'lock': Icons.lock,
    'lock_outline': Icons.lock_outline,
    'visibility': Icons.visibility,
    'visibility_off': Icons.visibility_off,
    'shield': Icons.shield,
    'home': Icons.home,
    'message': Icons.message,
    'star': Icons.star,
    'star_border': Icons.star_border,
    'push_pin': Icons.push_pin,
    'push_pin_outlined': Icons.push_pin_outlined,
    'more_vert': Icons.more_vert,
    'location_on': Icons.location_on,
    'access_time': Icons.access_time,
    'business': Icons.business,
    'monetization_on': Icons.monetization_on,
    'check_circle': Icons.check_circle,
    'card_giftcard': Icons.card_giftcard,
    'add': Icons.add,
    'add_photo_alternate': Icons.add_photo_alternate,
    'close': Icons.close,
    'image': Icons.image,
    'edit': Icons.edit,
    'remove_circle': Icons.remove_circle,
    'add_circle': Icons.add_circle,
    'drag_handle': Icons.drag_handle,
  };

  /// Returns the IconData for the given [key], or [defaultIcon] if not found.
  static IconData getIcon(String? key, {IconData defaultIcon = Icons.help_outline}) {
    if (key == null) return defaultIcon;
    return _iconMap[key] ?? defaultIcon;
  }

  /// Returns the key for the given [icon], or an empty string if not found.
  static String getIconKey(IconData icon) {
    for (var entry in _iconMap.entries) {
      if (entry.value == icon) return entry.key;
    }
    return '';
  }
}
