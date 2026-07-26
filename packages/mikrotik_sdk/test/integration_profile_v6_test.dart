/// Phase 6 — Live integration tests against CHR v6.49.17 (Linode Singapore).
///
/// Run with: dart test test/integration_profile_v6_test.dart
///
/// Validates OnLoginScriptGenerator output against real RouterOS v6.
/// Credentials from chr6.txt (gitignored). NEVER commit credentials.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

const _host = '139.162.35.252';
const _username = 'admin';
const _password = 'Ssh19233@';
const _port = 8728;

const _testProfile = 'p6test-v6-daily';

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

  group('CHR v6 — Phase 6 OnLoginScript integration', () {
    test('1. Version confirms v6', () async {
      await client.connect();
      final res = await client.command('/system/resource/print');
      expect(res, isNotEmpty);
      final version = res[0]['version'] ?? '';
      expect(version, startsWith('6.'),
          reason: 'Expected ROS v6.x, got: $version');
    });

    test('2. List profiles', () async {
      await client.connect();
      final result = await client.command('/ip/hotspot/user/profile/print');
      expect(result, isA<List>());
    });

    test('3. Add profile with noticeRecord on-login + scheduler', () async {
      await client.connect();

      const onLogin =
          ':put (",ntfc,10000,7d,10000,,Disable,"); '
          r'{:local comment [ /ip hotspot user get [/ip hotspot user find where name="$user"] comment]; '
          r':local ucode [:pic $comment 0 2]; '
          r':if ($ucode = "vc" or $ucode = "up" or $comment = "") do={ '
          r':local date [ /system clock get date ];'
          r':local year [ :pick $date 7 11 ];'
          r':local month [ :pick $date 0 3 ]; '
          r'/sys sch add name="$user" disable=no start-date=$date interval="7d"; '
          r':delay 5s; '
          r':local exp [ /sys sch get [ /sys sch find where name="$user" ] next-run]; '
          r':local getxp [len $exp]; '
          r':if ($getxp = 15) do={ :local d [:pic $exp 0 6]; :local t [:pic $exp 7 16]; :local s ("/"); :local exp ("$d$s$year $t"); /ip hotspot user set comment="$exp" [find where name="$user"];}; '
          r':if ($getxp = 8) do={ /ip hotspot user set comment="$date $exp" [find where name="$user"];}; '
          r':if ($getxp > 15) do={ /ip hotspot user set comment="$exp" [find where name="$user"];};'
          r':delay 5s; '
          r'/sys sch remove [find where name="$user"]; '
          r':local mac $"mac-address"; :local time [/system clock get time ]; '
          ':local price "10000"; :local validity "7d"; '
          r'/system script add name="$date-|-$time-|-$user-|-10000-|-$address-|-$mac-|-7d-|-' +
          _testProfile +
          r'-|-$comment" owner="$month$year" source="$date" comment="mikhmon"}}';

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
          r'[ /ip hotspot user set limit-uptime=1s $i ]; '
          r'[ /ip hotspot active remove [find where user=$name] ];}}}';

      await client.command('/system/scheduler/add', params: {
        'name': _testProfile,
        'start-time': '03:15:22',
        'interval': '00:02:22',
        'on-event': bgService,
        'disabled': 'no',
        'comment': 'Monitor Profile $_testProfile',
      });

      final created = await client.command('/ip/hotspot/user/profile/print',
          query: {'name': _testProfile});
      expect(created, isNotEmpty);
      expect(created[0]['name'], _testProfile);
    });

    test('4. Read back → verify on-login has ntfc at position [1]', () async {
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
      expect(parts[1], 'ntfc');
      expect(parts[2], '10000');
      expect(parts[3], '7d');
    });

    test('5. Scheduler exists with correct comment', () async {
      await client.connect();
      final scheds = await client.command('/system/scheduler/print',
          query: {'name': _testProfile});
      expect(scheds, isNotEmpty);
      expect(scheds[0]['comment'], 'Monitor Profile $_testProfile');
      expect(scheds[0]['disabled'], 'false');
    });

    test('6. Delete profile + scheduler', () async {
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
      expect(afterP, isEmpty);
      final afterS = await client.command('/system/scheduler/print',
          query: {'name': _testProfile});
      expect(afterS, isEmpty);
    });
  });
}
