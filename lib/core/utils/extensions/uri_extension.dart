extension UriExtension on Uri {
  Uri get previewOfficeUrl =>
      Uri.https('view.officeapps.live.com', '/op/view.aspx', {'src': toString()});
}
