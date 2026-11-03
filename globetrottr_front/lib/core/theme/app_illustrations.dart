/// Small pictures of the design taken from the mock-up. Their accent parts
/// follow the theme.
enum AppIllustrations {
  viewFog('view_fog'),
  viewStreets('view_streets'),
  viewHeatmap('view_heatmap'),
  viewVoronoi('view_voronoi');

  const AppIllustrations(this._file);

  final String _file;

  String get asset => 'assets/illustrations/$_file.svg';
}
