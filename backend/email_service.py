import os
import logging
from datetime import datetime, timedelta
from io import BytesIO

from fastapi import HTTPException, status
import resend
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT


logger = logging.getLogger(__name__)


class EmailService:
    """Reusable service for sending all PaLevel emails."""

    def build_email_html(self, subject: str, body_html: str) -> str:
        """Universal branded wrapper for all PaLevel HTML emails."""
        logo_url = f"{self.public_assets_url}PaLevel-Logo-Teal.png"
        kernelsoft_logo_url = f"{self.public_assets_url}KernelSoft-Logo-V1.png"

        return f'''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{subject}</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f7;font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f7;">
        <tr>
            <td align="center" style="padding:32px 0 16px;">
                <img src="{logo_url}" alt="PaLevel" width="160" height="56" style="display:block;margin:0 auto 12px;">
                <div style="font-size:29px;font-weight:700;color:#167c80;margin-bottom:0;">PaLevel</div>
            </td>
        </tr>
        <tr>
            <td align="center">
                <table width="100%" style="max-width:520px;background:#fff;border-radius:16px;box-shadow:0 10px 30px rgba(0,0,0,0.08);" cellpadding="0" cellspacing="0">
                    <tr><td style="padding:44px 36px;">{body_html}</td></tr>
                </table>
            </td>
        </tr>
        <tr>
            <td align="center" style="padding:20px 0 0;">
                <img src="{kernelsoft_logo_url}" alt="KernelSoft" width="80" height="24" style="display:block; margin: 0 auto 3px;">
                <div style="font-size:13px;color:#94a3b8;line-height:1.5;">Powered by KernelSoft<br>© {datetime.now().year} Kernelsoft LTD. All rights reserved.<br><span style="font-size:12px;color:#b2bac6;">This is an automated message — please do not reply.</span>
                </div>
            </td>
        </tr>
    </table>
</body>
</html>
'''
    def __init__(self) -> None:
        self.resend_api_key = os.getenv("RESEND_API_KEY")
        self.from_email = os.getenv("FROM_EMAIL", "onboarding@resend.dev")
        self.mail_from_name = os.getenv("MAIL_FROM_NAME", "")
        self.otp_expiry_minutes = int(os.getenv("OTP_EXPIRY_MINUTES", "10"))
        self.public_assets_url = os.getenv("PUBLIC_ASSETS_URL", "")  # Base URL for public images, trailing /
        # Initialize Resend client
        if self.resend_api_key:
            resend.api_key = self.resend_api_key

    async def send_otp_email(self, email: str, otp_code: str) -> None:
        from_email = f"{self.mail_from_name} <{self.from_email}>" if self.mail_from_name else self.from_email
        
        body_html = f'''
<h1 style="font-size: 28px; color: #1f2937; margin: 0 0 24px; font-weight: 600;">
    Your Verification Code for signing up for PaLevel
</h1>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">
    Enter this code to complete your sign up verification.
</p>
<div style="background-color: #f1f5f9; padding: 24px; border-radius: 12px; margin: 36px 0; border: 2px dashed #cbd5e1;">
    <div style="font-size: 38px; font-weight: bold; letter-spacing: 10px; color: #1e40af; font-family: 'Courier New', monospace;">
        {otp_code}
    </div>
</div>
<p style="font-size: 16px; color: #4b5563; margin: 0 0 32px;">
    This code expires in <strong>{self.otp_expiry_minutes} minutes</strong>.
</p>
<div style="padding-top: 32px; border-top: 1px solid #e2e8f0; margin-top: 40px;">
    <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0;">
        Didn't request this code? You can safely ignore this email.
    </p>
    <p style="font-size: 14px; color: #94a3b8; margin: 16px 0 0;">
        Never share this code — our team will never ask for it.
    </p>
</div>
'''
        html_body = self.build_email_html('Your PaLevel Verification Code', body_html)

        try:
            params = {
                "from": from_email,
                "to": [email],
                "subject": "Your OTP Code",
                "html": html_body
            }
            
            resend.Emails.send(params)
        except Exception as exc:  # pragma: no cover - network/Resend
            logger.error("Failed to send OTP email to %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send OTP email",
            ) from exc

    async def send_welcome_email(self, email: str, first_name: str, user_type: str) -> None:
        """Send welcome email to new users after role selection"""
        from_email = f"{self.mail_from_name} <{self.from_email}>" if self.mail_from_name else self.from_email
        
        # Different content based on user type
        if user_type == "tenant":
            subject = "Welcome to PaLevel!"
            title = "Welcome to PaLevel!"
            message = f"Hi {first_name},<br><br>Welcome to PaLevel! Your account has been successfully set up as a tenant. You can now browse available hostels, make bookings, and manage your accommodation all in one place."
        else:
            subject = "Welcome to PaLevel - Landlord!"
            title = "Welcome to PaLevel - Landlord!"
            message = f"Hi {first_name},<br><br>Welcome to PaLevel! Your account has been successfully set up as a landlord. You can now list your properties, manage bookings, and connect with tenants looking for accommodation."
        
        body_html = f'''
<h1 style="font-size: 28px; color: #1f2937; margin: 0 0 24px; font-weight: 600;">{title}</h1>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">{message}</p>
<div style="background-color: #f1f5f9; padding: 24px; border-radius: 12px; margin: 36px 0; border-left: 4px solid #167c80;">
    <h3 style="font-size: 18px; color: #1f2937; margin: 0 0 16px; font-weight: 600;">Getting Started</h3>
    <p style="font-size: 14px; color: #4b5563; line-height: 1.6; margin: 0;">
        {"Explore available hostels and book your perfect accommodation" if user_type == "tenant" else "List your properties and start receiving bookings from tenants"}.
    </p>
</div>
<div style="padding-top: 32px; border-top: 1px solid #e2e8f0; margin-top: 40px;">
    <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0;">Need help? contact our support team <a href='mailto:support@palevel.com'>support@palevel.com</a>.</p>
</div>
'''
        html_body = self.build_email_html(subject, body_html)
        
        try:
            params = {
                "from": from_email,
                "to": [email],
                "subject": subject,
                "html": html_body
            }
            
            resend.Emails.send(params)
            logger.info(f"Welcome email sent to {email}")
        except Exception as exc:
            logger.error("Failed to send welcome email to %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send welcome email",
            ) from exc
        
    async def send_profile_update_email(self, email: str, first_name: str) -> None:
        from_email = f"{self.mail_from_name} <{self.from_email}>" if self.mail_from_name else self.from_email
        
        body_html = f'''
<h1 style="font-size: 24px; color: #1f2937; margin: 0 0 24px; font-weight: 600;">Hi {first_name},</h1>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">Your PaLevel profile was updated successfully.<br>If you did not make this change, please contact support immediately.</p>
<div style="padding-top: 32px; border-top: 1px solid #e2e8f0; margin-top: 40px;">
    <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0;">Need help? contact our support team <a href='mailto:support@palevel.com'>support@palevel.com</a>.</p>
</div>
'''
        html_body = self.build_email_html('Your PaLevel Profile Was Updated', body_html)
        
        try:
            params = {
                "from": from_email,
                "to": [email],
                "subject": "Your Palevel Profile Was Updated",
                "html": html_body
            }
            
            resend.Emails.send(params)
        except Exception as exc:
            logger.error("Failed to send profile update email to %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send profile update email",
            ) from exc
    
    async def send_password_reset_email(self, email: str, first_name: str) -> None:
        from_email = f"{self.mail_from_name} <{self.from_email}>" if self.mail_from_name else self.from_email
        
        body_html = f'''
<h1 style="font-size: 28px; color: #1f2937; margin: 0 0 24px; font-weight: 600;">Password Changed Successfully</h1>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">Hi {first_name},<br><br>Your PaLevel account password has been successfully changed. You can now log in with your new password.</p>
<div style="background-color: #fef2f2; border-left: 4px solid #dc2626; padding: 16px; border-radius: 6px; margin: 32px 0; text-align: left;">
    <p style="font-size: 14px; color: #7f1d1d; margin: 0; font-weight: 500;">🔒 Security Tip</p>
    <p style="font-size: 14px; color: #991b1b; margin: 8px 0 0; line-height: 1.5;">If you did not request this password change, please reset your password immediately and contact our support team.</p>
</div>
<div style="padding-top: 32px; border-top: 1px solid #e2e8f0; margin-top: 40px;">
    <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0;">Need help? contact our support team <a href='mailto:support@palevel.com'>support@palevel.com</a>.</p>
</div>
'''
        html_body = self.build_email_html('Your PaLevel Password Has Been Changed', body_html)
        
        try:
            params = {
                "from": from_email,
                "to": [email],
                "subject": "Your Palevel Password Has Been Changed",
                "html": html_body
            }
            
            resend.Emails.send(params)
        except Exception as exc:
            logger.error("Failed to send password reset email to %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send password reset email",
            ) from exc
    
    def generate_booking_receipt_pdf(self, booking_data: dict) -> BytesIO:
        """Generate PDF receipt for booking"""
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=72, leftMargin=72, topMargin=72, bottomMargin=18)
        
        # Get styles
        styles = getSampleStyleSheet()
        
        # Custom styles
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30,
            alignment=TA_CENTER,
            textColor=colors.darkblue
        )
        
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=16,
            spaceAfter=12,
            textColor=colors.darkblue
        )
        
        normal_style = ParagraphStyle(
            'CustomNormal',
            parent=styles['Normal'],
            fontSize=11,
            spaceAfter=6
        )
        
        # Build PDF content
        story = []

        # --- Header with PaLevel Logo ---
        pa_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/PaLevel Logo-Teal.png')
        if os.path.exists(pa_logo_path):
            pa_logo = Image(pa_logo_path, width=130, height=45)
            pa_logo.hAlign = 'CENTER'
            story.append(pa_logo)
            story.append(Spacer(1, 10))
        story.append(Paragraph('<b>PaLevel</b>', ParagraphStyle('AppBrand', parent=title_style, fontSize=20, textColor=colors.HexColor('#167C80'), spaceAfter=6)))
        story.append(Paragraph("BOOKING RECEIPT", title_style))
        story.append(Spacer(1, 10))
        # Accent line
        story.append(Paragraph('<hr width="80%" color="#167C80"/>', normal_style))
        story.append(Spacer(1, 20))
        
        # Receipt info
        receipt_data = [
            ["Receipt Number:", f"RCP-{booking_data.get('booking_id', '')[:8].upper()}"],
            ["Date Issued:", datetime.now().strftime("%B %d, %Y")],
            ["Booking Status:", booking_data.get('status', '').upper()],
        ]
        
        receipt_table = Table(receipt_data, colWidths=[2*inch, 4*inch])
        receipt_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('BACKGROUND', (1, 0), (1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(receipt_table)
        story.append(Spacer(1, 20))
        
        # Student Information
        story.append(Paragraph("Student Information", heading_style))
        student_data = [
            ["Name:", booking_data.get('student_name', 'N/A')],
            ["Email:", booking_data.get('student_email', 'N/A')],
            ["Phone:", booking_data.get('student_phone', 'N/A')],
            ["University:", booking_data.get('student_university', 'N/A')],
        ]
        
        student_table = Table(student_data, colWidths=[1.5*inch, 4.5*inch])
        student_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('BACKGROUND', (1, 0), (1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(student_table)
        story.append(Spacer(1, 20))
        
        # Accommodation Details
        story.append(Paragraph("Accommodation Details", heading_style))
        accommodation_data = [
            ["Hostel Name:", booking_data.get('hostel_name', 'N/A')],
            ["Room Number:", booking_data.get('room_number', 'N/A')],
            ["Room Type:", booking_data.get('room_type', 'Standard')],
            ["Address:", booking_data.get('hostel_address', 'N/A')],
            ["Landlord:", booking_data.get('landlord_name', 'N/A')],
            ["Check-in:", booking_data.get('check_in', 'N/A')],
            ["Check-out:", booking_data.get('check_out', 'N/A')],
        ]
        
        accommodation_table = Table(accommodation_data, colWidths=[1.5*inch, 4.5*inch])
        accommodation_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('BACKGROUND', (1, 0), (1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(accommodation_table)
        story.append(Spacer(1, 20))
        
        # Payment Details
        story.append(Paragraph("Payment Details", heading_style))
        
        payment_data = [
            ["Payment Type:", booking_data.get('payment_type_display', 'N/A')],
            ["Monthly Rent:", f"MWK {booking_data.get('monthly_rent', '0.00')}"],
            ["Duration:", f"{booking_data.get('duration_months', 0)} month(s)"],
            ["Platform Fee:", f"MWK {booking_data.get('platform_fee', '0.00')}"],
        ]
        
        if booking_data.get('payment_type') == 'booking_fee':
            payment_data.append(["Booking Fee:", f"MWK {booking_data.get('booking_fee', '0.00')}"])
        else:
            room_total = float(booking_data.get('monthly_rent', 0)) * int(booking_data.get('duration_months', 0))
            payment_data.append(["Room Total:", f"MWK {room_total:.2f}"])
        
        payment_data.append(["Total Amount Paid:", f"MWK {booking_data.get('total_amount', '0.00')}"])
        
        if booking_data.get('payment_method'):
            payment_data.extend([
                ["Payment Method:", booking_data.get('payment_method')],
                ["Transaction ID:", booking_data.get('transaction_id', 'N/A')],
                ["Payment Date:", booking_data.get('payment_date', 'N/A')],
            ])
        
        payment_table = Table(payment_data, colWidths=[2*inch, 4*inch])
        payment_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('BACKGROUND', (1, 0), (1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('FONTNAME', (-1, -1), (-1, -1), 'Helvetica-Bold'),
            ('TEXTCOLOR', (-1, -1), (-1, -1), colors.darkgreen),
        ]))
        
        story.append(payment_table)
        story.append(Spacer(1, 30))
        
        # Terms and conditions
        story.append(Paragraph("Terms & Conditions", heading_style))
        terms = [
            "• This receipt serves as proof of payment for the mentioned accommodation.",
            "• The booking is subject to the terms and conditions of Palevel.",
            "• Please keep this receipt for your records.",
            "• For any inquiries, contact our support team.",
            "• This receipt is generated electronically and is valid without signature."
        ]
        
        for term in terms:
            story.append(Paragraph(term, normal_style))
        
        story.append(Spacer(1, 20))
        
        # Footer with KernelSoft logo
        story.append(Spacer(1, 30))
        kernel_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/KernelSoft-Logo-V1.png')
        if os.path.exists(kernel_logo_path):
            kernel_logo = Image(kernel_logo_path, width=80, height=25)
            kernel_logo.hAlign = 'CENTER'
            story.append(kernel_logo)
            story.append(Spacer(1, 6))
        footer_brand = '<font size="11" color="#167C80"><b>Powered by KernelSoft</b></font>'
        support = '<font size="9" color="gray">support@palevel.com | +265 883 271 664</font>'
        gen_time = f'<font size="9" color="gray">Generated by Palevel - {datetime.now().strftime("%B %d, %Y %H:%M:%S")}</font>'
        for html in [footer_brand, support, gen_time]:
            story.append(Paragraph(html, normal_style))
        story.append(Spacer(1, 3))
        disclaimer = '<font size="8" color="gray">This receipt is generated electronically and is valid without signature.</font>'
        story.append(Paragraph(disclaimer, normal_style))
        
        # Build PDF
        doc.build(story)
        
        # Get PDF bytes
        buffer.seek(0)
        return buffer

    async def send_booking_confirmation_email(self, email: str, first_name: str, booking_data: dict) -> None:
        """Send booking confirmation email with PDF receipt attachment"""
        from_email = f"{self.mail_from_name} <{self.from_email}>" if self.mail_from_name else self.from_email
        
        # Generate PDF receipt
        pdf_buffer = self.generate_booking_receipt_pdf(booking_data)
        pdf_bytes = pdf_buffer.getvalue()
        pdf_buffer.close()
        
        # Create attachment
        import base64
        pdf_base64 = base64.b64encode(pdf_bytes).decode()
        filename = f"booking_receipt_{booking_data.get('booking_id', '')[:8].upper()}.pdf"
        
        payment_type_display = booking_data.get('payment_type_display', 'Full Payment')
        is_booking_fee = payment_type_display == 'Booking Fee'
        
        # Different messaging for booking fee vs full payment
        if is_booking_fee:
            main_title = "Payment Completed!"
            main_message = f"Great news {first_name}! Your booking fee payment has been completed.<br>Your booking is now confirmed and the receipt is attached."
        else:
            main_title = "Booking Confirmed!"
            main_message = f"Congratulations {first_name}! Your booking has been confirmed.<br>Your accommodation details are below and your receipt is attached."
        
        body_html = f'''
<div style="background-color: #10b981; color: white; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px;">
    <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M5 13l4 4L19 7"/>
    </svg>
</div>
<h1 style="font-size: 28px; color: #1f2937; margin: 0 0 24px; font-weight: 600;">{main_title}</h1>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">{main_message}</p>
<div style="background-color: #f8fafc; padding: 24px; border-radius: 12px; margin: 32px 0; text-align: left;">
    <h3 style="font-size: 18px; color: #1f2937; margin: 0 0 16px; font-weight: 600;">Booking Summary</h3>
    <div style="font-size: 14px; color: #4b5563; line-height: 1.8;">
        <div style="margin-bottom: 8px;"><strong>Property:</strong> {booking_data.get('hostel_name', 'N/A')}</div>
        <div style="margin-bottom: 8px;"><strong>Room:</strong> {booking_data.get('room_number', 'N/A')}</div>
        <div style="margin-bottom: 8px;"><strong>Check-in:</strong> {booking_data.get('check_in', 'N/A')}</div>
        <div style="margin-bottom: 8px;"><strong>Check-out:</strong> {booking_data.get('check_out', 'N/A')}</div>
        <div style="margin-bottom: 8px;"><strong>Total Paid:</strong> MWK {booking_data.get('total_amount', '0.00')}</div>
    </div>
</div>
<div style="margin: 32px 0;">
    <div style="background-color: #167c80; color: white; padding: 16px 24px; border-radius: 8px; text-align: center; font-weight: 600;">📄 Your receipt is attached to this email</div>
</div>
<div style="padding-top: 32px; border-top: 1px solid #e2e8f0; margin-top: 40px;">
    <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0;">Need help? contact our support team <a href='mailto:support@palevel.com'>support@palevel.com</a>.</p>
</div>
'''
        # Different subject for booking fee vs full payment
        email_subject = f"{payment_type_display} Completed - Your Receipt is Attached" if is_booking_fee else "Booking Confirmation - Your Receipt is Attached"
        html_body = self.build_email_html(email_subject, body_html)

        try:
            params = {
                "from": from_email,
                "to": [email],
                "subject": email_subject,
                "html": html_body,
                "attachments": [
                    {
                        "filename": filename,
                        "content": pdf_base64,
                        "type": "application/pdf"
                    }
                ]
            }
            
            result = resend.Emails.send(params)
            logger.info(f"Booking confirmation email sent to {email}: {result}")
        except Exception as exc:
            logger.error("Failed to send booking confirmation email to %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send booking confirmation email",
            ) from exc
    
    async def send_booking_extension_email(self, email: str, first_name: str, booking_data: dict) -> None:
        """Send booking extension confirmation email with PDF receipt attachment"""
        logger.info(f"Attempting to send extension email to {email} for booking {booking_data.get('booking_id', 'N/A')}")
        
        # Check if Resend API key is configured
        if not self.resend_api_key:
            logger.error("RESEND_API_KEY is not configured - cannot send extension email")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Email service not configured",
            )
        
        from_email = f"{self.mail_from_name} <{self.from_email}>" if self.mail_from_name else self.from_email
        
        try:
            # Generate PDF receipt for extension
            logger.info("Generating extension PDF receipt")
            pdf_buffer = self.generate_extension_receipt_pdf(booking_data)
            pdf_bytes = pdf_buffer.getvalue()
            pdf_buffer.close()
            logger.info(f"PDF generated successfully, size: {len(pdf_bytes)} bytes")
            
            # Create attachment
            import base64
            pdf_base64 = base64.b64encode(pdf_bytes).decode()
            filename = f"extension_receipt_{booking_data.get('booking_id', '')[:8].upper()}.pdf"
            
            body_html = f'''
<h1 style="font-size: 28px; color: #1f2937; margin: 0 0 24px; font-weight: 600;">🗓️ Booking Extension Confirmed</h1>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 24px;">Dear <strong>{first_name}</strong>,</p>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">Great news! Your booking extension has been <span style="color: #167c80; font-weight: bold;">successfully processed</span>. Your stay has been extended and your booking details have been updated.</p>
<div style="background-color: #f8fafc; padding: 24px; border-radius: 12px; margin: 32px 0; text-align: left; border-left: 4px solid #167c80;">
    <h3 style="font-size: 18px; color: #1f2937; margin: 0 0 16px; font-weight: 600;">Extension Details</h3>
    <div style="font-size: 14px; color: #4b5563; line-height: 1.8;">
        <div style="margin-bottom: 8px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;"><strong>Booking ID:</strong> {booking_data.get('booking_id', '')[:8].upper()}</div>
        <div style="margin-bottom: 8px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;"><strong>Hostel:</strong> {booking_data.get('hostel_name', 'N/A')}</div>
        <div style="margin-bottom: 8px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;"><strong>Room Number:</strong> {booking_data.get('room_number', 'N/A')}</div>
        <div style="margin-bottom: 8px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;"><strong>Extension Amount:</strong> MWK {booking_data.get('extension_amount', '0.00')}</div>
        <div style="margin-bottom: 8px; padding-bottom: 8px; border-bottom: 1px solid #e2e8f0;"><strong>New Total Amount:</strong> MWK {booking_data.get('new_total_amount', '0.00')}</div>
        <div style="margin-bottom: 0;"><strong>Payment Date:</strong> {booking_data.get('payment_date', 'N/A')}</div>
    </div>
</div>
<div style="background-color: #e8f5e8; padding: 20px; border-radius: 12px; margin: 32px 0; text-align: center;">
    <h3 style="font-size: 18px; color: #28a745; margin: 0 0 12px; font-weight: 600;">📅 Updated Checkout Date</h3>
    <p style="margin: 0; font-size: 16px; color: #4b5563;"><strong>Your new checkout date is:</strong><br><span style="font-size: 20px; color: #28a745; font-weight: bold;">{booking_data.get('new_checkout_date', 'N/A')}</span></p>
</div>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 24px;">Please find your <strong>extension receipt</strong> attached to this email. This document contains all the details of your extension payment and updated booking information.</p>
<div style="background-color: #fff3cd; padding: 16px; border-radius: 8px; border-left: 4px solid #ffc107; margin: 24px 0;">
    <p style="margin: 0; font-size: 14px; color: #856404;"><strong>Important:</strong> Please save this email and the attached receipt for your records. You may need them for future reference.</p>
</div>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 24px;">If you have any questions about your extension or need further assistance, please don't hesitate to contact our support team.</p>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">Thank you for choosing to extend your stay with us!</p>
<div style="padding-top: 32px; border-top: 1px solid #e2e8f0; margin-top: 40px;">
    <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0;">Need help? contact our support team <a href='mailto:support@palevel.com'>support@palevel.com</a>.</p>
</div>
'''
            html_body = self.build_email_html(f"Booking Extension Confirmed - {booking_data.get('hostel_name', 'Hostel')} - Receipt Attached", body_html)
        
        except Exception as exc:
            logger.error("Failed to generate extension PDF or prepare email: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to prepare extension email",
            ) from exc
        
        try:
            params = {
                "from": from_email,
                "to": [email],
                "subject": f"Booking Extension Confirmed - {booking_data.get('hostel_name', 'Hostel')} - Receipt Attached",
                "html": html_body,
                "attachments": [
                    {
                        "filename": filename,
                        "content": pdf_base64,
                        "type": "application/pdf"
                    }
                ]
            }
            
            result = resend.Emails.send(params)
            logger.info(f"Booking extension email sent to {email}: {result}")
        except Exception as exc:
            logger.error("Failed to send booking extension email to %s: %s", email, exc)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send booking extension email",
            ) from exc
    
    def generate_extension_receipt_pdf(self, booking_data: dict) -> BytesIO:
        """Generate PDF receipt for booking extension"""
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=72, leftMargin=72, topMargin=72, bottomMargin=18)
        
        # Get styles
        styles = getSampleStyleSheet()
        
        # Custom styles
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30,
            alignment=TA_CENTER,
            textColor=colors.darkblue
        )
        
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=16,
            spaceAfter=12,
            textColor=colors.darkblue
        )
        
        normal_style = ParagraphStyle(
            'CustomNormal',
            parent=styles['Normal'],
            fontSize=11,
            spaceAfter=6
        )
        
        # Build PDF content
        story = []

        # --- Header with PaLevel Logo ---
        pa_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/PaLevel Logo-Teal.png')
        if os.path.exists(pa_logo_path):
            pa_logo = Image(pa_logo_path, width=130, height=45)
            pa_logo.hAlign = 'CENTER'
            story.append(pa_logo)
            story.append(Spacer(1, 10))
        story.append(Paragraph('<b>PaLevel</b>', ParagraphStyle('AppBrand', parent=title_style, fontSize=20, textColor=colors.HexColor('#167C80'), spaceAfter=6)))
        story.append(Paragraph("BOOKING EXTENSION RECEIPT", title_style))
        story.append(Spacer(1, 10))
        # Accent line
        story.append(Paragraph('<hr width="80%" color="#167C80"/>', normal_style))
        story.append(Spacer(1, 20))
        
        # Extension Details
        story.append(Paragraph("Extension Details", heading_style))
        
        extension_data = [
            ["Booking ID:", booking_data.get('booking_id', '')[:8].upper()],
            ["Student Name:", f"{booking_data.get('student_first_name', '')} {booking_data.get('student_last_name', '')}"],
            ["Student Email:", booking_data.get('student_email', '')],
            ["Hostel Name:", booking_data.get('hostel_name', '')],
            ["Room Number:", booking_data.get('room_number', '')],
            ["Room Type:", booking_data.get('room_type', '')],
            ["Extension Payment ID:", booking_data.get('extension_payment_id', '')[:8].upper()],
            ["Extension Payment Date:", booking_data.get('payment_date', 'N/A')],
            ["Previous Checkout Date:", booking_data.get('previous_checkout_date', 'N/A')],
            ["New Checkout Date:", booking_data.get('new_checkout_date', 'N/A')],
        ]
        
        extension_table = Table(extension_data, colWidths=[2*inch, 4*inch])
        extension_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('BACKGROUND', (1, 0), (1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(extension_table)
        
        story.append(Spacer(1, 20))
        
        # Payment Details
        story.append(Paragraph("Payment Details", heading_style))
        
        payment_data = [
            ["Monthly Rent:", f"MWK {booking_data.get('monthly_rent', '0.00')}"],
            ["Platform Fee:", f"MWK {booking_data.get('platform_fee', '0.00')}"],
            ["Total Extension Amount:", f"MWK {booking_data.get('extension_amount', '0.00')}"],
            ["Payment Method:", booking_data.get('payment_method', 'N/A')],
            ["Transaction ID:", booking_data.get('transaction_id', 'N/A')],
        ]
        
        payment_table = Table(payment_data, colWidths=[2*inch, 4*inch])
        payment_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('BACKGROUND', (1, 0), (1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('FONTNAME', (-1, -1), (-1, -1), 'Helvetica-Bold'),
            ('TEXTCOLOR', (-1, -1), (-1, -1), colors.darkgreen)
        ]))
        story.append(payment_table)
        
        story.append(Spacer(1, 30))
        
        story.append(Spacer(1, 30))
        
        # Footer with KernelSoft logo
        story.append(Spacer(1, 30))
        kernel_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/KernelSoft-Logo-V1.png')
        if os.path.exists(kernel_logo_path):
            kernel_logo = Image(kernel_logo_path, width=80, height=25)
            kernel_logo.hAlign = 'CENTER'
            story.append(kernel_logo)
            story.append(Spacer(1, 6))
        footer_brand = '<font size="11" color="#167C80"><b>Powered by KernelSoft</b></font>'
        support = '<font size="9" color="gray">support@palevel.com | +265 883 271 664</font>'
        gen_time = f'<font size="9" color="gray">Generated by Palevel - {datetime.now().strftime("%B %d, %Y %H:%M:%S")}</font>'
        for html in [footer_brand, support, gen_time]:
            story.append(Paragraph(html, normal_style))
        story.append(Spacer(1, 3))
        disclaimer = '<font size="8" color="gray">This receipt is generated electronically and is valid without signature.</font>'
        story.append(Paragraph(disclaimer, normal_style))
        
        # Build PDF
        doc.build(story)
        
        # Get PDF bytes
        buffer.seek(0)
        return buffer
    
    def generate_complete_payment_receipt_pdf(self, complete_payment_data: dict) -> BytesIO:
        """Generate PDF receipt for complete payment confirmation"""
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=72, leftMargin=72, topMargin=72, bottomMargin=18)
        story = []
        
        # Get styles
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30,
            alignment=1,  # Center alignment
            textColor=colors.darkgreen
        )
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=16,
            spaceAfter=12,
            textColor=colors.darkblue
        )
        normal_style = ParagraphStyle(
            'CustomNormal',
            parent=styles['Normal'],
            fontSize=11,
            spaceAfter=6
        )
        
        # --- Header with PaLevel Logo ---
        pa_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/PaLevel Logo-Teal.png')
        if os.path.exists(pa_logo_path):
            pa_logo = Image(pa_logo_path, width=130, height=45)
            pa_logo.hAlign = 'CENTER'
            story.append(pa_logo)
            story.append(Spacer(1, 10))
        story.append(Paragraph('<b>PaLevel</b>', ParagraphStyle('AppBrand', parent=title_style, fontSize=20, textColor=colors.HexColor('#167C80'), spaceAfter=6)))
        story.append(Paragraph("COMPLETE PAYMENT RECEIPT", title_style))
        story.append(Spacer(1, 10))
        # Accent line
        story.append(Paragraph('<hr width="80%" color="#167C80"/>', normal_style))
        story.append(Spacer(1, 20))
        
        # Payment Details Section
        story.append(Paragraph("Payment Details", heading_style))
        
        payment_details = [
            ["Booking ID:", complete_payment_data.get('booking_id', 'N/A')],
            ["Payment Date:", complete_payment_data.get('payment_date', 'N/A')],
            ["Payment Amount:", f"MK {complete_payment_data.get('complete_payment_amount', 'N/A')}"],
            ["Payment Method:", complete_payment_data.get('payment_method', 'N/A').upper()],
            ["Transaction ID:", complete_payment_data.get('transaction_id', 'N/A')],
            ["Payment Status:", "COMPLETED"],
        ]
        
        payment_table = Table(payment_details, colWidths=[2*inch, 4*inch])
        payment_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(payment_table)
        story.append(Spacer(1, 20))
        
        # Booking Details Section
        story.append(Paragraph("Booking Details", heading_style))
        
        booking_details = [
            ["Hostel:", complete_payment_data.get('hostel_name', 'N/A')],
            ["Room Number:", complete_payment_data.get('room_number', 'N/A')],
            ["Room Type:", complete_payment_data.get('room_type', 'N/A')],
            ["Checkout Date:", complete_payment_data.get('checkout_date', 'N/A')],
            ["Monthly Rent:", f"MK {complete_payment_data.get('monthly_rent', 'N/A')}"],
            ["Platform Fee:", f"MK {complete_payment_data.get('platform_fee', 'N/A')}"],
        ]
        
        booking_table = Table(booking_details, colWidths=[2*inch, 4*inch])
        booking_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(booking_table)
        story.append(Spacer(1, 20))
        
        # Student Details Section
        story.append(Paragraph("Student Details", heading_style))
        
        student_details = [
            ["Name:", f"{complete_payment_data.get('student_first_name', '')} {complete_payment_data.get('student_last_name', '')}"],
            ["Email:", complete_payment_data.get('student_email', 'N/A')],
        ]
        
        student_table = Table(student_details, colWidths=[2*inch, 4*inch])
        student_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(student_table)
        story.append(Spacer(1, 30))
        
        # Confirmation Message
        confirmation_text = """
        <b>Payment Confirmation:</b><br/>
        Your complete payment has been successfully processed. Your booking status has been 
        updated to "Paid in Full". You now have full access to your booking without any 
        further payment requirements.
        """
        
        story.append(Paragraph(confirmation_text, normal_style))
        story.append(Spacer(1, 20))
        
        story.append(Spacer(1, 20))
        
        # Footer with KernelSoft logo
        story.append(Spacer(1, 30))
        kernel_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/KernelSoft-Logo-V1.png')
        if os.path.exists(kernel_logo_path):
            kernel_logo = Image(kernel_logo_path, width=80, height=25)
            kernel_logo.hAlign = 'CENTER'
            story.append(kernel_logo)
            story.append(Spacer(1, 6))
        footer_brand = '<font size="11" color="#167C80"><b>Powered by KernelSoft</b></font>'
        support = '<font size="9" color="gray">support@palevel.com | +265 883 271 664</font>'
        gen_time = f'<font size="9" color="gray">Generated by Palevel - {datetime.now().strftime("%B %d, %Y %H:%M:%S")}</font>'
        for html in [footer_brand, support, gen_time]:
            story.append(Paragraph(html, normal_style))
        story.append(Spacer(1, 3))
        disclaimer = '<font size="8" color="gray">This receipt is generated electronically and is valid without signature.</font>'
        story.append(Paragraph(disclaimer, normal_style))
        
        # Build PDF
        doc.build(story)
        
        # Get PDF bytes
        buffer.seek(0)
        return buffer
    
    async def send_complete_payment_confirmation(self, email: str, complete_payment_data: dict) -> None:
        """Send complete payment confirmation email with PDF receipt attachment"""
        logger.info(f"Attempting to send complete payment confirmation email to {email} for booking {complete_payment_data.get('booking_id', 'N/A')}")
        
        # Check if Resend API key is configured
        if not self.resend_api_key:
            logger.error("RESEND_API_KEY is not configured - cannot send complete payment email")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Email service not configured",
            )
        
        from_email = f"{self.mail_from_name} <{self.from_email}>" if self.mail_from_name else self.from_email
        
        try:
            # Generate PDF receipt for complete payment
            logger.info("Generating complete payment PDF receipt")
            pdf_buffer = self.generate_complete_payment_receipt_pdf(complete_payment_data)
            pdf_bytes = pdf_buffer.getvalue()
            pdf_buffer.close()
            logger.info(f"PDF generated successfully, size: {len(pdf_bytes)} bytes")
            
            # Create attachment
            import base64
            pdf_base64 = base64.b64encode(pdf_bytes).decode()
            filename = f"complete_payment_receipt_{complete_payment_data.get('booking_id', '')[:8].upper()}.pdf"
            
            body_html = f'''
<div style="background-color: #10b981; color: white; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px;">
    <span style="font-size: 30px;">🎉</span>
</div>
<h1 style="font-size: 28px; color: #1f2937; margin: 0 0 24px; font-weight: 600;">Complete Payment Successful!</h1>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 24px;">Dear <strong>{complete_payment_data.get('student_first_name', 'Student')}</strong>,</p>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">Congratulations! Your complete payment has been successfully processed. Your booking is now fully paid and confirmed.</p>
<div style="background-color: #e8f5e8; padding: 24px; border-radius: 12px; margin: 32px 0; text-align: left; border-left: 4px solid #28a745;">
    <h3 style="font-size: 18px; color: #1f2937; margin: 0 0 16px; font-weight: 600;">Payment Details</h3>
    <div style="font-size: 14px; color: #4b5563; line-height: 1.8;">
        <div style="margin-bottom: 8px;"><strong>Booking ID:</strong> {complete_payment_data.get('booking_id', 'N/A')}</div>
        <div style="margin-bottom: 8px;"><strong>Hostel:</strong> {complete_payment_data.get('hostel_name', 'N/A')}</div>
        <div style="margin-bottom: 8px;"><strong>Room:</strong> {complete_payment_data.get('room_number', 'N/A')} ({complete_payment_data.get('room_type', 'N/A')})</div>
        <div style="margin-bottom: 8px;"><strong>Payment Amount:</strong> MWK {complete_payment_data.get('complete_payment_amount', 'N/A')}</div>
        <div style="margin-bottom: 8px;"><strong>Payment Date:</strong> {complete_payment_data.get('payment_date', 'N/A')}</div>
        <div style="margin-bottom: 0;"><strong>Transaction ID:</strong> {complete_payment_data.get('transaction_id', 'N/A')}</div>
    </div>
</div>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 24px;">Your booking status has been updated to <strong style="color: #28a745;">"Paid in Full"</strong>. You now have full access to your booking without any further payment requirements.</p>
<p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin: 0 0 36px;">A detailed PDF receipt has been attached to this email for your records.</p>
<div style="padding-top: 32px; border-top: 1px solid #e2e8f0; margin-top: 40px;">
    <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin: 0;">Need help? contact our support team <a href='mailto:support@palevel.com'>support@palevel.com</a>.</p>
</div>
'''
            html_body = self.build_email_html(f"Complete Payment Confirmation - Booking {complete_payment_data.get('booking_id', '')[:8].upper()}", body_html)
            
            params = {
                "from": from_email,
                "to": [email],
                "subject": f"Complete Payment Confirmation - Booking {complete_payment_data.get('booking_id', '')[:8].upper()}",
                "html": html_body,
                "attachments": [
                    {
                        "filename": filename,
                        "content": pdf_base64,
                        "type": "application/pdf"
                    }
                ]
            }
            
            logger.info(f"Sending complete payment email with PDF attachment: {filename}")
            result = resend.Emails.send(params)
            logger.info(f"Complete payment email sent successfully: {result}")
            
        except Exception as exc:
            logger.error(f"Failed to send complete payment confirmation email: {exc}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send complete payment confirmation email",
            ) from exc
    
    def otp_expiry(self) -> datetime:
        """Return the expiry datetime for a new OTP code."""

        return datetime.utcnow() + timedelta(minutes=self.otp_expiry_minutes)


email_service = EmailService()
