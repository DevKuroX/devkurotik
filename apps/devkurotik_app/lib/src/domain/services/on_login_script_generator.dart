/// Phase 6 — OnLoginScriptGenerator.
///
/// Generates byte-for-byte equivalent RouterScript output to Mikhmon v3
/// for all 5 supported expiry modes.
///
/// CANONICAL SOURCE: Mikhmon v3 hotspot/adduserprofile.php lines 62-86.
///
/// This generator MUST produce output identical to Mikhmon.
/// Any deviation is a FAILURE.
///
/// Change-control policy (per PHASE_6.md Task 11):
///   Any change to this module requires:
///   1. Fixture review — all 15+ golden fixtures must still pass.
///   2. Parser review — round-trip must still succeed for all modes.
///   3. Manual router validation on CHR v6 + v7.
///   4. Release note entry documenting the change rationale.
library;

import '../models/profile_models.dart';

/// Generates Mikhmon-compatible on-login and background sweep scripts.
///
/// Usage:
/// ```dart
/// final gen = OnLoginScriptGenerator();
/// final result = gen.generate(ProfileScriptParams(
///   profileName: 'daily',
///   mode: ExpiryMode.remove,
///   validity: '1d',
///   price: '5000',
///   sellingPrice: '5000',
///   macLock: false,
/// ));
/// // result.onLogin → write to /ip/hotspot/user/profile on-login field
/// // result.bgService → write to /system/scheduler on-event field
/// ```
class OnLoginScriptGenerator {
  const OnLoginScriptGenerator();

  /// Generates the complete profile script set for the given parameters.
  ///
  /// Throws [ArgumentError] if params are invalid.
  /// Never returns null.
  ProfileScriptResult generate(ProfileScriptParams params) {
    final validation = params.validate();
    if (!validation.isValid) {
      throw ArgumentError(
        'Invalid ProfileScriptParams: ${validation.errors.join('; ')}',
      );
    }

    return _buildResult(params);
  }

  ProfileScriptResult _buildResult(ProfileScriptParams params) {
    final lockFragment = _buildLockFragment(params.macLock);
    final modeToken = params.mode.token;
    final price = params.price.isEmpty ? '0' : params.price;
    final sprice = params.sellingPrice.isEmpty ? '0' : params.sellingPrice;

    String onLogin = '';
    String bgMode = '';
    String bgService = '';

    switch (params.mode) {
      case ExpiryMode.none:
        onLogin = _buildNoneOnLogin(price, params.macLock, lockFragment);
        bgMode = '';
        bgService = '';

      case ExpiryMode.remove:
        onLogin = _buildExpiryOnLogin(
          modeToken: modeToken,
          price: price,
          validity: params.validity,
          sprice: sprice,
          lockToken: _lockToken(params.macLock),
          lockFragment: lockFragment,
          recordFragment: '',
        );
        bgMode = 'remove';
        bgService = _buildBgService(params.profileName, bgMode);

      case ExpiryMode.notice:
        onLogin = _buildExpiryOnLogin(
          modeToken: modeToken,
          price: price,
          validity: params.validity,
          sprice: sprice,
          lockToken: _lockToken(params.macLock),
          lockFragment: lockFragment,
          recordFragment: '',
        );
        bgMode = 'set limit-uptime=1s';
        bgService = _buildBgService(params.profileName, bgMode);

      case ExpiryMode.removeRecord:
        final recordFragment = _buildRecordFragment(
          price: price,
          validity: params.validity,
          profileName: params.profileName,
        );
        onLogin = _buildExpiryOnLogin(
          modeToken: modeToken,
          price: price,
          validity: params.validity,
          sprice: sprice,
          lockToken: _lockToken(params.macLock),
          lockFragment: lockFragment,
          recordFragment: recordFragment,
        );
        bgMode = 'remove';
        bgService = _buildBgService(params.profileName, bgMode);

      case ExpiryMode.noticeRecord:
        final recordFragment = _buildRecordFragment(
          price: price,
          validity: params.validity,
          profileName: params.profileName,
        );
        onLogin = _buildExpiryOnLogin(
          modeToken: modeToken,
          price: price,
          validity: params.validity,
          sprice: sprice,
          lockToken: _lockToken(params.macLock),
          lockFragment: lockFragment,
          recordFragment: recordFragment,
        );
        bgMode = 'set limit-uptime=1s';
        bgService = _buildBgService(params.profileName, bgMode);
    }

    return ProfileScriptResult(
      onLogin: onLogin,
      bgService: bgService,
      mode: bgMode,
      params: params,
    );
  }

  // ---------------------------------------------------------------------------
  // Canonical on-login builders
  // ---------------------------------------------------------------------------

  /// Builds on-login for ExpiryMode.none.
  ///
  /// Canonical rules from adduserprofile.php line 80-83:
  ///   - if expmode == "0" AND price != "":
  ///       ':put (",,' + price + ',,,noexp,' + getlock + ',')'  + lock
  ///   - else (expmode == "0" AND price == "" or == "0"):
  ///       ""  (empty string)
  String _buildNoneOnLogin(String price, bool macLock, String lockFragment) {
    if (price != '0' && price.isNotEmpty) {
      // ignore: unnecessary_brace_in_string_interps
      return ':put (",,${price},,,noexp,${_lockToken(macLock)},")'
          '$lockFragment';
    }
    return '';
  }

  /// Builds on-login for Remove / Notice / RemoveRecord / NoticeRecord.
  ///
  /// Canonical template from adduserprofile.php line 65:
  ///
  /// $onlogin = ':put (",'+$expmode+','+$price+','+$validity+','+$sprice+',,'+$getlock+',");
  ///  {:local comment [/ip hotspot user get [...] comment];
  ///   :local ucode [:pic $comment 0 2];
  ///   :if ($ucode = "vc" or $ucode = "up" or $comment = "") do={
  ///     :local date [/system clock get date];
  ///     :local year [:pick $date 7 11];
  ///     :local month [:pick $date 0 3];
  ///     /sys sch add name="$user" disable=no start-date=$date interval="'+$validity+'";
  ///     :delay 5s;
  ///     :local exp [/sys sch get [/sys sch find where name="$user"] next-run];
  ///     :local getxp [len $exp];
  ///     :if ($getxp = 15) do={...};
  ///     :if ($getxp = 8) do={...};
  ///     :if ($getxp > 15) do={...};
  ///     :delay 5s;
  ///     /sys sch remove [find where name="$user"]'
  ///
  /// Then appended:
  ///   - record fragment (for remc/ntfc)
  ///   - lock fragment (if macLock)
  ///   - "}}"
  String _buildExpiryOnLogin({
    required String modeToken,
    required String price,
    required String validity,
    required String sprice,
    required String lockToken,
    required String lockFragment,
    required String recordFragment,
  }) {
    final header =
        ':put (",$modeToken,$price,$validity,$sprice,,$lockToken,");'
        ' {:local comment [ /ip hotspot user get [/ip hotspot user find where name="\$user"] comment];'
        ' :local ucode [:pic \$comment 0 2];'
        ' :if (\$ucode = "vc" or \$ucode = "up" or \$comment = "") do={'
        ' :local date [ /system clock get date ];'
        ':local year [ :pick \$date 7 11 ];'
        ':local month [ :pick \$date 0 3 ];'
        ' /sys sch add name="\$user" disable=no start-date=\$date interval="$validity";'
        ' :delay 5s;'
        ' :local exp [ /sys sch get [ /sys sch find where name="\$user" ] next-run];'
        ' :local getxp [len \$exp];'
        ' :if (\$getxp = 15) do={'
        ' :local d [:pic \$exp 0 6];'
        ' :local t [:pic \$exp 7 16];'
        ' :local s ("/");'
        ' :local exp ("\$d\$s\$year \$t");'
        ' /ip hotspot user set comment="\$exp" [find where name="\$user"];};'
        ' :if (\$getxp = 8) do={'
        ' /ip hotspot user set comment="\$date \$exp" [find where name="\$user"];};'
        ' :if (\$getxp > 15) do={'
        ' /ip hotspot user set comment="\$exp" [find where name="\$user"];};'
        ':delay 5s;'
        ' /sys sch remove [find where name="\$user"]';

    return '$header$recordFragment$lockFragment}}';
  }

  // ---------------------------------------------------------------------------
  // Canonical record fragment builder
  // ---------------------------------------------------------------------------

  /// Builds the sale record fragment appended to remc/ntfc on-login.
  ///
  /// Canonical template from adduserprofile.php line 63:
  /// $record = '; :local mac $"mac-address";
  ///   :local time [/system clock get time ];
  ///   /system script add name="$date-|-$time-|-$user-|-'+$price+'-|-$address-|-$mac-|-'+$validity+'-|-'+$name+'-|-$comment"
  ///   owner="$month$year" source="$date" comment="mikhmon"'
  String _buildRecordFragment({
    required String price,
    required String validity,
    required String profileName,
  }) {
    return '; :local mac \$"mac-address";'
        ' :local time [/system clock get time ];'
        ' /system script add name="\$date-|-\$time-|-\$user-|'
        '-$price-|-\$address-|-\$mac-|-$validity-|-$profileName-|-\$comment"'
        ' owner="\$month\$year" source="\$date" comment="mikhmon"';
  }

  // ---------------------------------------------------------------------------
  // Canonical MAC lock fragment builder
  // ---------------------------------------------------------------------------

  /// Builds the MAC lock fragment.
  ///
  /// Canonical from adduserprofile.php line 53:
  ///   '; [:local mac $"mac-address";
  ///      /ip hotspot user set mac-address=$mac [find where name=$user]]'
  String _buildLockFragment(bool macLock) {
    if (!macLock) return '';
    return '; [:local mac \$"mac-address";'
        ' /ip hotspot user set mac-address=\$mac [find where name=\$user]]';
  }

  // ---------------------------------------------------------------------------
  // Canonical background sweep service builder
  // ---------------------------------------------------------------------------

  /// Builds the background sweep scheduler on-event script.
  ///
  /// Canonical template from adduserprofile.php line 86:
  ///
  /// $bgservice = ':local dateint do={...date int converter...};
  ///   :local timeint do={...time int converter...};
  ///   :local date [/system clock get date];
  ///   :local time [/system clock get time];
  ///   :local today [$dateint d=$date];
  ///   :local curtime [$timeint t=$time];
  ///   :foreach i in [/ip hotspot user find where profile="'+$name+'"] do={
  ///     :local comment [/ip hotspot user get $i comment];
  ///     :local name [/ip hotspot user get $i name];
  ///     :local gettime [:pic $comment 12 20];
  ///     :if ([:pic $comment 3] = "/" and [:pic $comment 6] = "/") do={
  ///       :local expd [$dateint d=$comment];
  ///       :local expt [$timeint t=$gettime];
  ///       :if (($expd < $today and $expt < $curtime)
  ///            or ($expd < $today and $expt > $curtime)
  ///            or ($expd = $today and $expt < $curtime)) do={
  ///         [/ip hotspot user '+$mode+' $i];
  ///         [/ip hotspot active remove [find where user=$name]];
  ///       }
  ///     }
  ///   }'
  String _buildBgService(String profileName, String mode) {
    return ':local dateint do={'
        ':local montharray ( "jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec" );'
        ':local days [ :pick \$d 4 6 ];'
        ':local month [ :pick \$d 0 3 ];'
        ':local year [ :pick \$d 7 11 ];'
        ':local monthint ([ :find \$montharray \$month]);'
        ':local month (\$monthint + 1);'
        ':if ( [len \$month] = 1) do={'
        ':local zero ("0");'
        ':return [:tonum ("\$year\$zero\$month\$days")];}'
        ' else={'
        ':return [:tonum ("\$year\$month\$days")];}}; '
        ':local timeint do={'
        ' :local hours [ :pick \$t 0 2 ];'
        ' :local minutes [ :pick \$t 3 5 ];'
        ' :return (\$hours * 60 + \$minutes) ; }; '
        ':local date [ /system clock get date ]; '
        ':local time [ /system clock get time ]; '
        ':local today [\$dateint d=\$date] ; '
        ':local curtime [\$timeint t=\$time] ; '
        ':foreach i in [ /ip hotspot user find where profile="$profileName" ] do={'
        ' :local comment [ /ip hotspot user get \$i comment];'
        ' :local name [ /ip hotspot user get \$i name];'
        ' :local gettime [:pic \$comment 12 20];'
        ' :if ([:pic \$comment 3] = "/" and [:pic \$comment 6] = "/") do={'
        ':local expd [\$dateint d=\$comment] ;'
        ' :local expt [\$timeint t=\$gettime] ;'
        ' :if ((\$expd < \$today and \$expt < \$curtime)'
        ' or (\$expd < \$today and \$expt > \$curtime)'
        ' or (\$expd = \$today and \$expt < \$curtime)) do={'
        ' [ /ip hotspot user $mode \$i ];'
        ' [ /ip hotspot active remove [find where user=\$name] ];}}}';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _lockToken(bool macLock) => macLock ? 'Enable' : 'Disable';
}
