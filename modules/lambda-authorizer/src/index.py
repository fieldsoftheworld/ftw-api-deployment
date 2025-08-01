import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    
    #Lambda authorizer to validate CloudFront secret header
    #Returns 403 if X-CloudFront-Secret header is missing or incorrect
    
    try:
        # Validate event structure
        if not event or 'headers' not in event:
            logger.error("Malformed event: missing headers")
            return deny_response("Malformed request")
        
        # Get headers (handle case variations)
        headers = event.get('headers', {})
        
        # Handle case-insensitive header lookup
        secret_header = None
        for key, value in headers.items():
            if key.lower() == 'x-cloudfront-secret':
                secret_header = value
                break
        
        # Get expected secret
        expected_secret = os.environ.get('CLOUDFRONT_SECRET')
        if not expected_secret:
            logger.error("CLOUDFRONT_SECRET environment variable not set")
            return deny_response("Configuration error")
        
        # Validate secret
        if not secret_header:
            logger.info("Missing CloudFront secret header")
            return deny_response("Missing authorization header")
        
        if secret_header != expected_secret:
            logger.warning("Invalid CloudFront secret header")
            return deny_response("Invalid authorization")
        
        logger.info("CloudFront secret header validated successfully")
        return allow_response()
        
    except Exception as e:
        logger.error(f"Unexpected error in authorizer: {str(e)}")
        return deny_response("Authorization error")

def allow_response():
    return {
        'isAuthorized': True,
        'context': {
            'source': 'cloudfront'
        }
    }

def deny_response(reason):
    return {
        'isAuthorized': False,
        'context': {
            'reason': reason
        }
    }