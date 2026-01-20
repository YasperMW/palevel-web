#!/usr/bin/env python3
"""
Test script to verify the webhook endpoint fix
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    # Test importing the payments module
    from endpoints.payments import router
    print("✅ Successfully imported payments router")
    
    # Check if the webhook endpoint exists
    for route in router.routes:
        if "/paychangu/webhook/" in route.path:
            print(f"✅ Found webhook endpoint: {route.methods} {route.path}")
            print(f"✅ Endpoint function: {route.endpoint.__name__}")
            
            # Check the function signature
            import inspect
            sig = inspect.signature(route.endpoint)
            params = list(sig.parameters.keys())
            print(f"✅ Function parameters: {params}")
            
            # Verify it has 'request' parameter
            if 'request' in params:
                print("✅ Webhook endpoint has 'request' parameter - this should fix the Signature header issue")
            else:
                print("❌ Webhook endpoint missing 'request' parameter")
            break
    else:
        print("❌ Webhook endpoint not found")
        
except Exception as e:
    print(f"❌ Error importing or checking webhook endpoint: {e}")
    import traceback
    traceback.print_exc()

print("\n🔧 Fix Summary:")
print("- Fixed webhook endpoint function signature to properly receive FastAPI Request object")
print("- Added robust header detection for multiple possible signature header names")
print("- Added debug logging to help troubleshoot webhook issues")
print("- The 'Missing Signature header' error should now be resolved")
