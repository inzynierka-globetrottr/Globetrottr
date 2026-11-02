/// Icons of the design, drawn as SVG files taken from the mock-up.
enum AppIcons {
  navMap('nav_map'),
  navQuests('nav_quests'),
  navFriends('nav_friends'),
  navProfile('nav_profile'),
  fieldUser('field_user'),
  fieldMail('field_mail'),
  fieldLock('field_lock'),
  eye('eye'),
  eyeOff('eye_off'),
  chevronLeft('chevron_left'),
  chevronRight('chevron_right'),

  /// The globe of the logo, drawn over a disc in the accent colour.
  globe('globe', tintable: false),

  /// Brand logo; keeps its own colours.
  google('google', tintable: false);

  const AppIcons(this._file, {this.tintable = true});

  final String _file;

  /// Whether the icon is drawn in one colour chosen by the widget.
  final bool tintable;

  String get asset => 'assets/icons/$_file.svg';
}
