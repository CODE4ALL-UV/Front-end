import 'external_url_opener_stub.dart'
    if (dart.library.html) 'external_url_opener_web.dart'
    as impl;

Future<bool> openExternalUrl(String url) => impl.openExternalUrl(url);
