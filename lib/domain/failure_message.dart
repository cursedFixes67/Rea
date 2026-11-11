import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class FailureMessage {
  final String message;
  final String details;
  const FailureMessage(this.message, this.details);
  factory FailureMessage.from(Object error) {
    final details = error is PlatformException
        ? '${error.code}: ${error.message ?? 'Unknown native error'}'
        : error.toString();
    final lower = details.toLowerCase();
    if (lower.contains('typereference') || lower.contains('injekt')) {
      return FailureMessage(
        'Dream Reader could not initialize its extension engine. Install the latest app update, then try again.',
        details,
      );
    }
    if (lower.contains('signature') ||
        lower.contains('signer') ||
        lower.contains('package identity')) {
      return FailureMessage(
        'The downloaded extension could not be verified. Refresh the repository and try again. Only install packages from a repository you trust.',
        details,
      );
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return FailureMessage(
        'The request took too long. Check your connection and try again.',
        details,
      );
    }
    if (error is DioException && error.response == null) {
      return FailureMessage(
        'Could not reach the server. Check your connection and try again.',
        details,
      );
    }
    if (lower.contains('http 403') ||
        lower.contains('http 503') ||
        lower.contains('cloudflare')) {
      return FailureMessage(
        'The source may require website verification. Open its website from the source menu, complete the check, then retry.',
        details,
      );
    }
    if (error is PlatformException) {
      return FailureMessage(
        error.code == 'ENGINE_RESTART'
            ? 'The extension process restarted. Try this request again.'
            : 'The request could not finish. Try again, or check for an extension update.',
        details,
      );
    }
    return FailureMessage(
      details.replaceFirst(
        RegExp(r'^(Exception|StateError|Bad state|FormatException): '),
        '',
      ),
      details,
    );
  }
}
