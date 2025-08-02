"""AWS Lambda authorizer for CloudFront secret header validation.

This module provides a Lambda function that validates CloudFront secret headers
to ensure API Gateway requests originate from CloudFront and not direct access.
"""

import logging
import os
from typing import Any

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

CLOUDFRONT_SECRET_HEADER = "x-cloudfront-secret"
CLOUDFRONT_SECRET_ENV_VAR = "CLOUDFRONT_SECRET"


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Lambda authorizer to validate CloudFront secret header.

    Args:
        event: The Lambda event containing request headers and metadata
        context: The Lambda context object (unused)

    Returns:
        Authorization response with isAuthorized boolean and context

    Raises:
        No exceptions are raised; all errors are caught and result in denial
    """
    try:
        # Validate event structure
        if not event or "headers" not in event:
            logger.error("Malformed event: missing headers")
            return _deny_response("Malformed request")

        headers = event.get("headers", {})

        # (case-insensitive)
        secret_header = _get_cloudfront_secret_header(headers)

        expected_secret = os.environ.get(CLOUDFRONT_SECRET_ENV_VAR)
        if not expected_secret:
            logger.error("CLOUDFRONT_SECRET environment variable not set")
            return _deny_response("Configuration error")

        if not secret_header:
            logger.info("Missing CloudFront secret header")
            return _deny_response("Missing authorization header")

        if secret_header != expected_secret:
            logger.warning("Invalid CloudFront secret header")
            return _deny_response("Invalid authorization")

        logger.info("CloudFront secret header validated successfully")
        return _allow_response()

    except Exception as e:
        logger.error("Unexpected error in authorizer: %s", str(e))
        return _deny_response("Authorization error")


def _get_cloudfront_secret_header(headers: dict[str, str]) -> str | None:
    """Extract CloudFront secret header with case-insensitive lookup.

    Args:
        headers: Dictionary of HTTP headers

    Returns:
        The CloudFront secret header value if found, None otherwise
    """
    for key, value in headers.items():
        if key.lower() == CLOUDFRONT_SECRET_HEADER:
            return value
    return None


def _allow_response() -> dict[str, Any]:
    """Generate authorization allow response.

    Returns:
        Dictionary with isAuthorized=True and context metadata
    """
    return {"isAuthorized": True, "context": {"source": "cloudfront"}}


def _deny_response(reason: str) -> dict[str, Any]:
    """Generate authorization deny response.

    Args:
        reason: Human-readable reason for denial

    Returns:
        Dictionary with isAuthorized=False and context with reason
    """
    return {"isAuthorized": False, "context": {"reason": reason}}
