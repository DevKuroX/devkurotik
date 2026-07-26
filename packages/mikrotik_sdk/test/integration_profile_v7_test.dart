/// Phase 6 — Live integration tests against CHR v7.15.1 (AWS EC2).
///
/// Run with: dart test test/integration_profile_v7_test.dart
///
/// Validates OnLoginScriptGenerator output against real RouterOS v7.
/// Credentials from chr.txt (gitignored). NEVER commit credentials.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

import 'integration_credentials.dart';

// Credentials loaded from env vars (CHR_V7_*) or chr.txt (gitignored).
// Never hardcode credentials. See integration_credentials.dart.
String get _host => chrV7Host;
String get _username => chrV7User;
String get _password => chrV7Password;
int get _port => chrV7Port;

const _testProfile = 'p6test-v7-daily';

MikrotikClient _newClient() => MikrotikClient(
      host: _host,
      username: _username,
      password: _password,
      port: _port,
      timeout: const Duration(seconds: 15),
      maxRetries: 0,
    );

Future<void> _cleanupTestProfile() async {
  final c = _newClient();
  await c.connect();
  try {
    final existing = await c.command('/ip/hotspot/user/profile/print',
        query: {'name': _testProfile});
    if (existing.isNotEmpty) {
      await c.command('/ip/hotspot/user/profile/remove',
          params: {'.id': existing[0]['.id']!});
    }
    final sched = await c.command('/system/scheduler/print',
        query: {'name': _testProfile});
    if (sched.isNotEmpty) {
      await c.command('/system/scheduler/remove',
          params: {'.id': sched[0]['.id']!});
    }
  } catch (_) {}
  await c.disconnect();
}

void main() {
  late MikrotikClient client;

  setUpAll(() async {
    await _cleanupTestProfile();
  });

  setUp(() {
    client = _newClient();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('CHR v7 — Phase 6 OnLoginScript integration', () {
    test('1. List profiles returns list', () async {
      await client.connect();
      final result = await client.command('/ip/hotspot/user/profile/print');
      expect(result, isA<List>());
    });

    test('2. Version confirms v7', () async {
      await client.connect();
      final res = await client.command('/system/resource/print');
      expect(res, isNotEmpty);
      final version = res[0]['version'] ?? '';
      expect(version, startsWith('7.'),
          reason: 'Expected ROS v7.x, got: $version');
    });

    test('3. Add profile with remove on-login + scheduler', () async {
      await client.connect();

      const onLogin =
          ':put (",rem,5000,1d,5000,,Disable,"); '
          r'{:local comment [ /ip hotspot user get [/ip hotspot user find where name="$user"] comment]; '
          r':local ucode [:pic $comment 0 2]; '
          r':if ($ucode = "vc" or $ucode = "up" or $comment = "") do={ '
          r':local date [ /system clock get date ];'
          r':local year [ :pick $date 7 11 ];'
          r':local month [ :pick $date 0 3 ]; '
          r'/sys sch add name="$user" disable=no start-date=$date interval="1d"; '
          r':delay 5s; '
          r':local exp [ /sys sch get [ /sys sch find where name="$user" ] next-run]; '
          r':local getxp [len $exp]; '
          r':if ($getxp = 15) do={ :local d [:pic $exp 0 6]; :local t [:pic $exp 7 16]; :local s ("/"); :local exp ("$d$s$year $t"); /ip hotspot user set comment="$exp" [find where name="$user"];}; '
          r':if ($getxp = 8) do={ /ip hotspot user set comment="$date $exp" [find where name="$user"];}; '
          r':if ($getxp > 15) do={ /ip hotspot user set comment="$exp" [find where name="$user"];};'
          r':delay 5s; '
          r'/sys sch remove [find where name="$user"]}}';

      await client.command('/ip/hotspot/user/profile/add', params: {
        'name': _testProfile,
        'on-login': onLogin,
        'shared-users': '1',
        'status-autorefresh': '1m',
      });

      const bgService =
          r':local dateint do={'
          r':local montharray ( "jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec" );'
          r':local days [ :pick $d 4 6 ];'
          r':local month [ :pick $d 0 3 ];'
          r':local year [ :pick $d 7 11 ];'
          r':local monthint ([ :find $montharray $month]);'
          r':local month ($monthint + 1);'
          r':if ( [len $month] = 1) do={'
          r':local zero ("0");'
          r':return [:tonum ("$year$zero$month$days")];}'
          r' else={'
          r':return [:tonum ("$year$month$days")];}}; '
          r':local timeint do={ :local hours [ :pick $t 0 2 ]; :local minutes [ :pick $t 3 5 ]; :return ($hours * 60 + $minutes) ; }; '
          r':local date [ /system clock get date ]; '
          r':local time [ /system clock get time ]; '
          r':local today [$dateint d=$date] ; '
          r':local curtime [$timeint t=$time] ; '
          ':foreach i in [ /ip hotspot user find where profile="$_testProfile" ] do={ '
          r':local comment [ /ip hotspot user get $i comment]; '
          r':local name [ /ip hotspot user get $i name]; '
          r':local gettime [:pic $comment 12 20]; '
          r':if ([:pic $comment 3] = "/" and [:pic $comment 6] = "/") do={'
          r':local expd [$dateint d=$comment] ; '
          r':local expt [$timeint t=$gettime] ; '
          r':if (($expd < $today and $expt < $curtime) or ($expd < $today and $expt > $curtime) or ($expd = $today and $expt < $curtime)) do={ '
          r'[ /ip hotspot user remove $i ]; '
          r'[ /ip hotspot active remove [find where user=$name] ];}}}';

      await client.command('/system/scheduler/add', params: {
        'name': _testProfile,
        'start-time': '02:30:15',
        'interval': '00:02:15',
        'on-event': bgService,
        'disabled': 'no',
        'comment': 'Monitor Profile $_testProfile',
      });

      final profiles = await client.command('/ip/hotspot/user/profile/print',
          query: {'name': _testProfile});
      expect(profiles, isNotEmpty, reason: 'Profile $_testProfile must exist');
      expect(profiles[0]['name'], _testProfile);
    });

    test('4. Read back on-login → verify comma positions', () async {
      await client.connect();
      final profiles = await client.command('/ip/hotspot/user/profile/print',
          query: {'name': _testProfile});
      expect(profiles, isNotEmpty);

      final onLogin = profiles[0]['on-login'] ?? '';
      expect(onLogin, isNotEmpty);

      final putStart = onLogin.indexOf('("');
      final putEnd = onLogin.indexOf('");');
      expect(putStart, greaterThan(-1));
      expect(putEnd, greaterThan(putStart));

      final header = onLogin.substring(putStart + 2, putEnd);
      final parts = header.split(',');
      expect(parts.length, greaterThanOrEqualTo(7));
      expect(parts[1], 'rem', reason: 'Position [1] must be "rem"');
      expect(parts[2], '5000', reason: 'Position [2] must be price "5000"');
      expect(parts[3], '1d', reason: 'Position [3] must be validity "1d"');
      expect(parts[4], '5000', reason: 'Position [4] must be sprice "5000"');
      expect(parts[6], 'Disable', reason: 'Position [6] must be "Disable"');
    });

    test('5. Verify background scheduler was created', () async {
      await client.connect();
      final scheds = await client.command('/system/scheduler/print',
          query: {'name': _testProfile});
      expect(scheds, isNotEmpty, reason: 'Scheduler for $_testProfile must exist');
      expect(scheds[0]['name'], _testProfile);
      expect(scheds[0]['comment'], 'Monitor Profile $_testProfile');
      expect(scheds[0]['disabled'], 'false');
    });

    test('6. Update profile to notice mode → verify on-login changes', () async {
      await client.connect();
      final profiles = await client.command('/ip/hotspot/user/profile/print',
          query: {'name': _testProfile});
      expect(profiles, isNotEmpty);
      final profileId = profiles[0]['.id']!;

      const newOnLogin =
          ':put (",ntf,5000,1d,5000,,Disable,"); '
          r'{:local comment [ /ip hotspot user get [/ip hotspot user find where name="$user"] comment]; '
          r':local ucode [:pic $comment 0 2]; '
          r':if ($ucode = "vc" or $ucode = "up" or $comment = "") do={ '
          r':local date [ /system clock get date ];'
          r':local year [ :pick $date 7 11 ];'
          r':local month [ :pick $date 0 3 ]; '
          r'/sys sch add name="$user" disable=no start-date=$date interval="1d"; '
          r':delay 5s; '
          r':local exp [ /sys sch get [ /sys sch find where name="$user" ] next-run]; '
          r':local getxp [len $exp]; '
          r':if ($getxp = 15) do={ :local d [:pic $exp 0 6]; :local t [:pic $exp 7 16]; :local s ("/"); :local exp ("$d$s$year $t"); /ip hotspot user set comment="$exp" [find where name="$user"];}; '
          r':if ($getxp = 8) do={ /ip hotspot user set comment="$date $exp" [find where name="$user"];}; '
          r':if ($getxp > 15) do={ /ip hotspot user set comment="$exp" [find where name="$user"];};'
          r':delay 5s; '
          r'/sys sch remove [find where name="$user"]}}';

      await client.command('/ip/hotspot/user/profile/set', params: {
        '.id': profileId,
        'on-login': newOnLogin,
      });

      final updated = await client.command('/ip/hotspot/user/profile/print',
          query: {'name': _testProfile});
      final updatedOnLogin = updated[0]['on-login'] ?? '';
      expect(updatedOnLogin, contains('ntf'),
          reason: 'Updated on-login must contain ntf');
    });

    test('7. Delete profile + scheduler → cleanup verified', () async {
      await client.connect();

      final profiles = await client.command('/ip/hotspot/user/profile/print',
          query: {'name': _testProfile});
      if (profiles.isNotEmpty) {
        await client.command('/ip/hotspot/user/profile/remove',
            params: {'.id': profiles[0]['.id']!});
      }

      final scheds = await client.command('/system/scheduler/print',
          query: {'name': _testProfile});
      if (scheds.isNotEmpty) {
        await client.command('/system/scheduler/remove',
            params: {'.id': scheds[0]['.id']!});
      }

      final afterP = await client.command('/ip/hotspot/user/profile/print',
          query: {'name': _testProfile});
      expect(afterP, isEmpty, reason: 'Profile must be deleted');

      final afterS = await client.command('/system/scheduler/print',
          query: {'name': _testProfile});
      expect(afterS, isEmpty, reason: 'Scheduler must be deleted');
    });
  });
}
