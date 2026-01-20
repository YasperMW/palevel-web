from fastapi import APIRouter, HTTPException, status
from typing import List, Dict, Any
from pydantic import BaseModel, UUID4
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

class BankProvider(BaseModel):
    uuid: UUID4
    name: str

class BankProvidersResponse(BaseModel):
    data: List[BankProvider]

@router.get("/banks/providers", response_model=BankProvidersResponse, status_code=status.HTTP_200_OK)
async def get_banks_and_providers():
    """
    Get list of banks and mobile money providers with their UUIDs
    """
    try:
        # Static data as provided by the user
        banks_and_providers = [
            {
                "uuid": "82310dd1-ec9b-4fe7-a32c-2f262ef08681",
                "name": "National Bank of Malawi"
            },
            {
                "uuid": "87e62436-0553-4fb5-a76d-f27d28420c5b",
                "name": "Ecobank Malawi Limited"
            },
            {
                "uuid": "b064172a-8a1b-4f7f-aad7-81b036c46c57",
                "name": "FDH Bank Limited"
            },
            {
                "uuid": "e7447c2c-c147-4907-b194-e087fe8d8585",
                "name": "Standard Bank Limited"
            },
            {
                "uuid": "236760c9-3045-4a01-990e-497b28d115bb",
                "name": "Centenary Bank"
            },
            {
                "uuid": "968ac588-3b1f-4d89-81ff-a3d43a599003",
                "name": "First Capital Limited"
            },
            {
                "uuid": "c759d7b6-ae5c-4a95-814a-79171271897a",
                "name": "CDH Investment Bank"
            },
            {
                "uuid": "5e9946ae-76ed-43f5-ad59-63e09096006a",
                "name": "TNM Mpamba"
            },
            {
                "uuid": "e8d5fca0-e5ac-4714-a518-484be9011326",
                "name": "Airtel Money"
            },
            {
                "uuid": "86007bf5-1b04-49ba-84c1-9758bbf5c996",
                "name": "NBS Bank Limited"
            }
        ]
        
        logger.info(f"Returning {len(banks_and_providers)} banks and mobile money providers")
        
        return BankProvidersResponse(data=banks_and_providers)
        
    except Exception as e:
        logger.error(f"Error fetching banks and providers: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not fetch banks and mobile money providers"
        )
