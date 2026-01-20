import os
import logging
from typing import Any, Dict, Optional
from datetime import datetime
import time

import requests
from sqlalchemy.orm import Session

from database import db_session
from models import Disbursement

logger = logging.getLogger(__name__)

# Environment variables (set these in your environment or .env file)
# Use PAYCHANGU_API_KEY if present; Fall back to PAYCHANGU_SECRET_KEY if set in .env
PAYCHANGU_API_KEY = os.getenv("PAYCHANGU_API_KEY") or os.getenv("PAYCHANGU_SECRET_KEY")
PAYCHANGU_BASE_URL = os.getenv("PAYCHANGU_BASE_URL", "https://api.paychangu.com")
# Optional defaults and polling configuration
PAYCHANGU_DEFAULT_BANK_UUID = os.getenv("PAYCHANGU_DEFAULT_BANK_UUID")
PAYCHANGU_POLL_RETRIES = int(os.getenv("PAYCHANGU_POLL_RETRIES", "5"))
PAYCHANGU_POLL_INTERVAL = int(os.getenv("PAYCHANGU_POLL_INTERVAL", "5"))


class PayChanguError(Exception):
    pass


class PayChanguClient:
    """Small client for interacting with PayChangu transfer endpoints.

    This implementation keeps paths configurable since PayChangu's docs use
    several endpoints depending on the operation (direct charge, transfers,
    bulk transfers etc.). The helper methods below implement the common
    transfer/payout flows needed for landlord disbursements.
    """

    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None):
        self.api_key = api_key or PAYCHANGU_API_KEY
        self.base_url = base_url or PAYCHANGU_BASE_URL
        if not self.api_key:
            raise PayChanguError("PAYCHANGU_API_KEY is not set in environment")

    def _headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

    def _post(self, path: str, payload: Dict[str, Any], timeout: int = 30) -> Dict[str, Any]:
        """Internal helper to post data to PayChangu and handle responses uniformly."""
        url = f"{self.base_url}{path}"
        logger.info("Posting to PayChangu %s: %s", url, {"payload": payload})
        resp = requests.post(url, json=payload, headers=self._headers(), timeout=timeout)
        try:
            data = resp.json()
        except ValueError:
            logger.error("Non-json response from PayChangu: %s", resp.text)
            raise PayChanguError("Invalid response from PayChangu")

        # PayChangu sometimes uses boolean `status` or a string - normalise it
        status = data.get("status")
        if resp.status_code >= 400 or status not in ("success", True):
            message = data.get("message") or data.get("error") or resp.text
            logger.error("PayChangu request failed: %s", message)
            raise PayChanguError(message)

        return data

    def create_transfer(self, *, amount: float, currency: str, bank_uuid: str, bank_account_number: str, bank_account_name: str, charge_id: str, extra: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Generic transfer call using PayChangu's `/transfers` endpoint.

        This can be used for simple bank/mobile transfers when the payload is the
        standard shape. Use `create_bank_transfer` or `create_mobile_money_transfer`
        if you need to target their specific shapes.
        """
        payload = {
            "amount": str(int(amount)),  # smallest unit/integers as per PayChangu
            "currency": currency,
            "bank_uuid": bank_uuid,
            "bank_account_number": bank_account_number,
            "bank_account_name": bank_account_name,
            "charge_id": charge_id,
        }
        if extra:
            payload.update(extra)

        return self._post("/transfers", payload)

    def create_bank_transfer(self, *, amount: float, currency: str, bank_uuid: str, account_number: str, account_name: str, charge_id: str, payout_method: str | None = None, extra: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Create a bank transfer (payout) using PayChangu Bank Payout API.

        Uses the documented endpoint POST /direct-charge/payouts/initialize.
        """
        payload = {
            "amount": str(int(amount)),
            "currency": currency,
            "bank_uuid": bank_uuid,
            "bank_account_number": account_number,
            "bank_account_name": account_name,
            "charge_id": charge_id,
            # Use 'bank_transfer' to match internal payment_method naming and likely accepted values
            "payout_method": "bank_transfer"
        }
        if extra:
            payload.update(extra)
        # Bank payouts use the direct-charge payouts initialize endpoint
        return self._post("/direct-charge/payouts/initialize", payload)

    def create_mobile_money_transfer(self, *, amount: float, mobile_number: str, charge_id: str, mobile_money_operator_ref_id: str | None = None, extra: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Create a mobile money transfer (payout) using PayChangu Mobile Money Payout API.

        Uses the documented endpoint POST /mobile-money/payouts/initialize.
        Only required fields: amount, mobile, mobile_money_operator_ref_id, charge_id.
        """
        send_format = os.getenv("PAYCHANGU_MOBILE_NUMBER_FORMAT", "string").lower()

        mobile_val = None
        if mobile_number is not None:
            s = str(mobile_number)
            if send_format == "int":
                if s.isdigit():
                    try:
                        mobile_val = int(s)
                    except Exception:
                        mobile_val = s
                else:
                    mobile_val = s
            else:
                mobile_val = s if s.startswith("0") else "0" + s

        payload = {
            "amount": str(int(amount)),
            "mobile": mobile_val,
            "charge_id": str(charge_id),
        }
        if mobile_money_operator_ref_id:
            payload["mobile_money_operator_ref_id"] = str(mobile_money_operator_ref_id)
        if extra:
            payload.update(extra)
        return self._post("/mobile-money/payouts/initialize", payload)

    def get_transfer(self, transfer_id: str) -> Dict[str, Any]:
        """Deprecated: older endpoint path; kept for compatibility."""
        url = f"{self.base_url}/transfers/{transfer_id}"
        resp = requests.get(url, headers=self._headers(), timeout=20)
        try:
            data = resp.json()
        except ValueError:
            raise PayChanguError("Invalid response from PayChangu when fetching transfer")

        if resp.status_code >= 400:
            message = data.get("message") or resp.text
            raise PayChanguError(message)
        return data

    def get_payout_details_by_charge(self, charge_id: str) -> Dict[str, Any]:
        """Fetch payout details using the charge_id (documented path).

        GET /direct-charge/payouts/{charge_id}/details
        """
        url = f"{self.base_url}/direct-charge/payouts/{charge_id}/details"
        resp = requests.get(url, headers=self._headers(), timeout=20)
        try:
            data = resp.json()
        except ValueError:
            raise PayChanguError("Invalid response from PayChangu when fetching payout details")

        if resp.status_code >= 400:
            message = data.get("message") or resp.text
            raise PayChanguError(message)
        return data

def _normalize_mobile_number(mobile: Optional[str]) -> Optional[str]:
    if not mobile:
        return mobile
    s = str(mobile).strip()
    s = s.replace(" ", "")
    # Remove leading +country or country code for Malawi (+265 or 265) and leading zero
    if s.startswith("+"):
        if s.startswith("+265"):
            s = s[4:]
        else:
            s = s[1:]
    if s.startswith("265"):
        s = s[3:]
    if s.startswith("0"):
        s = s[1:]
    # Keep digits only
    s = ''.join(ch for ch in s if ch.isdigit())
    return s


def process_disbursement(
    disbursement_id: str,
    *,
    payment_method: str = "bank_transfer",
    bank_uuid: Optional[str] = None,
    bank_account_number: Optional[str] = None,
    bank_account_name: Optional[str] = None,
    mobile_number: Optional[str] = None,
    mobile_account_name: Optional[str] = None,
    mobile_money_operator_ref_id: Optional[str] = None,
    currency: str = "MWK",
) -> Disbursement:
    """High-level helper to send a disbursement via PayChangu and update the DB record.

    Supports two payment methods:
    - `bank_transfer` (requires `bank_uuid`, `bank_account_number`, `bank_account_name`)
    - `mobile_money` (requires `bank_uuid`, `mobile_number`, `mobile_account_name`)

    The function will:
    - Load the Disbursement record from the database
    - Mark it as `processing` and commit
    - Call the appropriate PayChangu transfer API
    - Update the Disbursement with `payment_reference`, `status`, `processed_at` or `failure_reason`
    """
    client = PayChanguClient()

    # If caller did not provide a bank_uuid, fall back to the environment default (if set).
    bank_uuid = bank_uuid or PAYCHANGU_DEFAULT_BANK_UUID

    # Normalize and validate bank_uuid if present
    if bank_uuid:
        try:
            import uuid as _uuid
            # allow uuid.UUID or string; convert to canonical string
            bank_uuid = str(_uuid.UUID(str(bank_uuid)))
        except Exception as e:
            raise ValueError(f"Invalid bank_uuid provided: {bank_uuid}") from e

    with db_session() as db:
        disb = db.query(Disbursement).filter(Disbursement.disbursement_id == disbursement_id).first()
        if not disb:
            raise ValueError("Disbursement not found")

        # Set to processing
        disb.status = "processing"
        db.commit()

        try:
            charge_id = f"disb_{disbursement_id}"

            if payment_method in ("bank_transfer", "bank"):
                if not (bank_uuid and bank_account_number and bank_account_name):
                    raise ValueError("bank_uuid, bank_account_number and bank_account_name are required for bank transfers")
                print("Here1..... Bank transfer initiated")
                resp = client.create_bank_transfer(
                    amount=float(disb.disbursement_amount),
                    currency=currency,
                    bank_uuid=bank_uuid,
                    account_number=bank_account_number,
                    account_name=bank_account_name,
                    charge_id=charge_id,
                    payout_method="bank",
                )
                disb.payment_method = "bank_transfer"

            elif payment_method in ("mobile_money", "mobile"):
                # Normalize and validate mobile number to the expected local format (strip country code)
                mobile_number = _normalize_mobile_number(mobile_number)
                if mobile_number and not str(mobile_number).startswith('0'):
                    mobile_number = '0' + str(mobile_number)
                mobile_money_operator_ref_id = mobile_money_operator_ref_id or os.getenv("PAYCHANGU_MOBILE_OPERATOR_REF_ID")

                if not mobile_number:
                    raise ValueError("mobile_number is required for mobile money transfers")

                resp = client.create_mobile_money_transfer(
                    amount=float(disb.disbursement_amount),
                    mobile_number=mobile_number,
                    charge_id=charge_id,
                    mobile_money_operator_ref_id=mobile_money_operator_ref_id,
                )
                disb.payment_method = "mobile_money"

            else:
                raise ValueError(f"Unsupported payment_method: {payment_method}")

            # Parse response for reference id
            reference = None
            if isinstance(resp, dict):
                reference = (
                    resp.get("data", {}).get("transaction", {}).get("ref_id")
                    or resp.get("data", {}).get("ref_id")
                    or resp.get("data", {}).get("id")
                    or resp.get("ref_id")
                )

            disb.payment_reference = reference
            # Keep record in processing state until PayChangu confirms settlement
            disb.status = "processing"
            db.commit()
            db.refresh(disb)

            # Try to extract a transfer ID to poll
            transfer_id = (
                reference or
                (resp.get("data") or {}).get("id") or
                resp.get("id")
            )

            # Helper to read status from a transfer payload
            def _extract_status(transfer_data: Dict[str, Any]) -> Optional[str]:
                if not isinstance(transfer_data, dict):
                    return None
                # Common places for a status
                status = (
                    transfer_data.get("data", {}).get("transaction", {}).get("status")
                    or transfer_data.get("data", {}).get("status")
                    or transfer_data.get("status")
                    or transfer_data.get("data", {}).get("transaction", {}).get("state")
                )
                return status.lower() if isinstance(status, str) else None

            completed_states = ("completed", "success", "settled", "paid")
            failed_states = ("failed", "error", "rejected", "cancelled")

            if not transfer_id:
                logger.warning("No transfer id available from PayChangu response; leaving disbursement in processing: %s", disbursement_id)
                return disb

            # Poll the transfer status until settled or failure
            for attempt in range(1, PAYCHANGU_POLL_RETRIES + 1):
                try:
                    # Prefer polling by charge_id (we set it to disb_<id> earlier) which uses the documented
                    # GET /direct-charge/payouts/{charge_id}/details endpoint. Fall back to transfer_id if needed.
                    transfer = client.get_payout_details_by_charge(charge_id)
                except Exception as e:
                    logger.warning("Attempt %s: failed to fetch payout details %s: %s", attempt, charge_id, str(e))
                    if attempt < PAYCHANGU_POLL_RETRIES:
                        time.sleep(PAYCHANGU_POLL_INTERVAL)
                    continue

                status = _extract_status(transfer)
                logger.info("Payout %s status check attempt %s: %s", charge_id, attempt, status)

                if status in completed_states:
                    disb.payment_reference = transfer_id or charge_id
                    disb.status = "completed"
                    disb.processed_at = datetime.utcnow()
                    db.commit()
                    db.refresh(disb)
                    logger.info("Disbursement %s completed (charge id %s)", disbursement_id, charge_id)
                    return disb

                if status in failed_states:
                    disb.payment_reference = transfer_id or charge_id
                    disb.status = "failed"
                    disb.failure_reason = f"Transfer failed with status {status}"
                    disb.processed_at = datetime.utcnow()
                    db.commit()
                    db.refresh(disb)
                    logger.error("Disbursement %s failed (charge id %s): %s", disbursement_id, charge_id, status)
                    raise PayChanguError(f"Transfer failed with status {status}")

                # still pending
                if attempt < PAYCHANGU_POLL_RETRIES:
                    time.sleep(PAYCHANGU_POLL_INTERVAL)

            # If we reach here, transfer is still pending after retries; leave as processing
            logger.info("Transfer %s still pending after %s attempts; leaving disbursement as processing", transfer_id, PAYCHANGU_POLL_RETRIES)
            return disb

        except Exception as exc:  # pylint: disable=broad-except
            logger.exception("Disbursement processing failed for %s", disbursement_id)
            disb.status = "failed"
            disb.failure_reason = str(exc)
            disb.processed_at = datetime.utcnow()
            db.commit()
            db.refresh(disb)
            raise
