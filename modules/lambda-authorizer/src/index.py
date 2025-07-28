import json
import os

def lambda_handler(event, context):
    """
    Lambda authorizer to validate CloudFront secret header
    Returns 403 if X-CloudFront-Secret header is missing or incorrect
    """
    
    # Get expected secret from environment variable
    expected_secret = os.environ.get('CLOUDFRONT_SECRET')
    
    if not expected_secret:
        print("ERROR: CLOUDFRONT_SECRET environment variable not set")
        return generate_policy('Deny', event['routeArn'])
    
    # Get headers from the request
    headers = event.get('headers', {})
    
    # Check for X-CloudFront-Secret header (case-insensitive)
    cloudfront_secret = None
    for header_name, header_value in headers.items():
        if header_name.lower() == 'x-cloudfront-secret':
            cloudfront_secret = header_value
            break
    
    if not cloudfront_secret:
        print("DENIED: Missing X-CloudFront-Secret header")
        return generate_policy('Deny', event['routeArn'])
    
    if cloudfront_secret != expected_secret:
        print("DENIED: Invalid X-CloudFront-Secret header")
        return generate_policy('Deny', event['routeArn'])
    
    print("ALLOWED: Valid CloudFront secret header")
    return generate_policy('Allow', event['routeArn'])

def generate_policy(effect, resource):
    """Generate IAM policy for API Gateway"""
    return {
        'principalId': 'cloudfront-user',
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        }
    }
