// This file is the conditional import router.
// On web builds (dart.library.html), the stub is loaded — mock data, no Supabase.
// On mobile builds (dart.library.io), the mobile implementation is loaded — real Supabase.
export 'app_services_stub.dart'
    if (dart.library.io) 'app_services_mobile.dart';
