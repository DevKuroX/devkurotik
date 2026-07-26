/// RouterOS connection state enumeration.
library;

/// Represents the current state of a [MikrotikConnection].
enum ConnectionState {
  /// No connection attempt has been made.
  disconnected,

  /// A connection attempt is in progress.
  connecting,

  /// Connected and authenticated — ready for commands.
  connected,

  /// Connection was lost unexpectedly (socket error, timeout).
  lost,

  /// Disconnection is in progress.
  disconnecting,
}
