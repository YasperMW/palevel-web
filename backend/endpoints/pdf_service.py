from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.orm import Session, joinedload
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from io import BytesIO
import os
from datetime import datetime
from database import get_db
from models import Booking as BookingModel, Payment, Room, Hostel, User, Configuration
from endpoints.users import get_current_user
from decimal import Decimal
import uuid

router = APIRouter(prefix="/pdf", tags=["pdf"])

def get_platform_fee(db: Session) -> Decimal:
    """Get platform fee from configuration"""
    config = db.query(Configuration).filter(Configuration.config_key == "platform_fee").first()
    return Decimal(str(config.config_value)) if config else Decimal('0')

@router.get("/booking-receipt/{booking_id}")
async def generate_booking_receipt(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate PDF receipt for a booking"""
    
    # Debug logging
    print(f"PDF Receipt Request - Booking ID: {booking_id}")
    print(f"PDF Receipt Request - User ID: {current_user.user_id}")
    print(f"PDF Receipt Request - User Email: {current_user.email}")
    print(f"PDF Receipt Request - User Type: {current_user.user_type}")
    
    # First check if booking exists at all
    booking_exists = db.query(BookingModel).filter(BookingModel.booking_id == booking_id).first()
    
    if not booking_exists:
        print(f"PDF Receipt Request - Booking {booking_id} does not exist in database")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Booking with ID {booking_id} not found"
        )
    
    print(f"PDF Receipt Request - Booking exists, belongs to student_id: {booking_exists.student_id}")
    
    # Check if user has permission (is the student who made the booking, admin, or landlord of the property)
    has_permission = False
    
    # Admin can access all receipts
    if current_user.user_type.lower() == 'admin':
        has_permission = True
        print(f"PDF Receipt Request - Admin access granted")
    # Student can access their own receipts
    elif booking_exists.student_id == current_user.user_id:
        has_permission = True
        print(f"PDF Receipt Request - Student access granted")
    # Landlord can access receipts for their properties
    elif current_user.user_type.lower() == 'landlord':
        # Check if the booking is for a room that belongs to this landlord
        room_info = (
            db.query(Room)
            .join(Hostel)
            .filter(Room.room_id == booking_exists.room_id, Hostel.landlord_id == current_user.user_id)
            .first()
        )
        if room_info:
            has_permission = True
            print(f"PDF Receipt Request - Landlord access granted for their property")
        else:
            print(f"PDF Receipt Request - Landlord access denied - not their property")
    
    if not has_permission:
        print(f"PDF Receipt Request - Permission denied for user {current_user.user_id} ({current_user.user_type})")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this booking receipt. Only the student who made the booking, the property landlord, or admins can access it."
        )
    
    # Get booking with all related data
    booking = (
        db.query(BookingModel)
        .options(
            joinedload(BookingModel.student),
            joinedload(BookingModel.room)
            .joinedload(Room.hostel)
            .joinedload(Hostel.landlord),
            joinedload(BookingModel.payments)
        )
        .filter(BookingModel.booking_id == booking_id)
        .first()
    )
    
    print(f"PDF Receipt Request - Booking with relations loaded: {booking is not None}")
    
    if not booking:
        print(f"PDF Receipt Request - Failed to load booking relations")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to load booking details"
        )
    
    # Create PDF buffer
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
    pa_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/PaLevel-Logo-Teal.png')
    if os.path.exists(pa_logo_path):
        pa_logo = Image(pa_logo_path, width=130, height=45)  # Or adjust size
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
        ["Receipt Number:", f"RCP-{booking.booking_id.hex[:8].upper()}"],
        ["Date Issued:", datetime.now().strftime("%B %d, %Y")],
        ["Booking Status:", booking.status.upper()],
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
        ["Name:", f"{booking.student.first_name} {booking.student.last_name}"],
        ["Email:", booking.student.email],
        ["Phone:", booking.student.phone_number or "N/A"],
        ["University:", booking.student.university or "N/A"],
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
        ["Hostel Name:", booking.room.hostel.name],
        ["Room Number:", booking.room.room_number],
        ["Room Type:", booking.room.type or "Standard"],
        ["Address:", booking.room.hostel.address or "N/A"],
        ["Landlord:", f"{booking.room.hostel.landlord.first_name} {booking.room.hostel.landlord.last_name}"],
        ["Check-in:", booking.start_date.strftime("%B %d, %Y")],
        ["Check-out:", booking.end_date.strftime("%B %d, %Y")],
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
    
    # Use stored duration_months from booking instead of calculating
    duration_months = booking.duration_months
    
    platform_fee = get_platform_fee(db)
    
    payment_data = [
        ["Payment Type:", "Full Payment" if booking.payment_type == "full" else "Booking Fee"],
        ["Monthly Rent:", f"MWK {booking.room.price_per_month:.2f}"],
        ["Duration:", f"{duration_months} month(s)"],
        ["Platform Fee:", f"MWK {platform_fee:.2f}"],
    ]
    
    if booking.payment_type == "booking_fee":
        hostel = booking.room.hostel
        # Use booking fee from hostel database (should always be set)
        if hostel.booking_fee is not None:
            booking_fee = hostel.booking_fee
            print(f"PDF Receipt: Using hostel booking fee from database: {booking_fee}")
        else:
            # This should not happen if data is properly configured
            booking_fee = Decimal('0.00')
            print(f"PDF Receipt: Warning - Hostel booking fee is None, using 0.00")
        payment_data.append(["Booking Fee:", f"MWK {booking_fee:.2f}"])
    else:
        room_total = booking.room.price_per_month * Decimal(duration_months)
        payment_data.append(["Room Total:", f"MWK {room_total:.2f}"])
    
    payment_data.append(["Total Amount Paid:", f"MWK {booking.total_amount:.2f}"])
    
    # Add payment method if available
    if booking.payments:
        latest_payment = sorted(booking.payments, key=lambda p: p.paid_at or datetime.min, reverse=True)[0]
        payment_data.extend([
            ["Payment Method:", latest_payment.payment_method],
            ["Transaction ID:", latest_payment.transaction_id or "N/A"],
            ["Payment Date:", latest_payment.paid_at.strftime("%B %d, %Y") if latest_payment.paid_at else "N/A"],
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
    support = '<font size="9" color="gray">kernelsoft1@gmail.com | +265 883 271 664</font>'
    gen_time = f'<font size="9" color="gray">Generated by Palevel - {datetime.now().strftime('%B %d, %Y %H:%M:%S')}</font>'
    for html in [footer_brand, support, gen_time]:
        story.append(Paragraph(html, normal_style))
    story.append(Spacer(1, 3))
    disclaimer = '<font size="8" color="gray">This receipt is generated electronically and is valid without signature.</font>'
    story.append(Paragraph(disclaimer, normal_style))
    
    # Build PDF
    doc.build(story)
    
    # Get PDF bytes
    buffer.seek(0)
    pdf_bytes = buffer.getvalue()
    buffer.close()
    
    # Return PDF response
    filename = f"booking_receipt_{booking.booking_id.hex[:8]}.pdf"
    
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename={filename}",
            "Content-Length": str(len(pdf_bytes))
        }
    )


@router.get("/extension-receipt/{booking_id}")
async def generate_extension_receipt(
    booking_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate PDF receipt for a booking extension"""
    
    # Get booking with extension payment
    booking = (
        db.query(BookingModel)
        .options(
            joinedload(BookingModel.student),
            joinedload(BookingModel.room).joinedload(Room.hostel),
            joinedload(BookingModel.payments)
        )
        .filter(BookingModel.booking_id == booking_id)
        .first()
    )
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Booking with ID {booking_id} not found"
        )
    
    # Check permissions (same as regular receipt)
    has_permission = False
    if current_user.user_type.lower() == 'admin':
        has_permission = True
    elif booking.student_id == current_user.user_id:
        has_permission = True
    elif current_user.user_type.lower() == 'landlord':
        room_info = (
            db.query(Room)
            .join(Hostel, Room.hostel_id == Hostel.hostel_id)
            .filter(
                Room.room_id == booking.room_id,
                Hostel.landlord_id == current_user.user_id
            )
            .first()
        )
        if room_info:
            has_permission = True
    
    if not has_permission:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this extension receipt"
        )
    
    # Get extension payment
    extension_payment = None
    for payment in booking.payments:
        if payment.payment_type == "extension" and payment.status == "completed":
            extension_payment = payment
            break
    
    if not extension_payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No completed extension payment found for this booking"
        )
    
    # Create PDF buffer
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=72, leftMargin=72, topMargin=72, bottomMargin=18)
    
    # Styles
    styles = getSampleStyleSheet()
    title_style = styles['Title']
    heading_style = styles['Heading1']
    normal_style = styles['Normal']
    
    # Build PDF content
    story = []
    # --- Header with PaLevel Logo ---
    pa_logo_path = os.path.join(os.path.dirname(__file__), '../lib/assets/images/PaLevel-Logo-Teal.png')
    if os.path.exists(pa_logo_path):
        pa_logo = Image(pa_logo_path, width=130, height=45)
        pa_logo.hAlign = 'CENTER'
        story.append(pa_logo)
        story.append(Spacer(1, 10))
    story.append(Paragraph('<b>PaLevel</b>', ParagraphStyle('AppBrand', parent=title_style, fontSize=20, textColor=colors.HexColor('#167C80'), spaceAfter=6)))
    story.append(Paragraph("BOOKING EXTENSION RECEIPT", title_style))
    story.append(Spacer(1, 10))
    story.append(Paragraph('<hr width="80%" color="#167C80"/>', normal_style))
    story.append(Spacer(1, 20))
    
    # Receipt Info Table
    receipt_data = [
        ["Extension Receipt #:", f"EXT-{extension_payment.payment_id.hex[:8].upper()}"],
        ["Date Issued:", datetime.now().strftime("%B %d, %Y")],
        ["Extension Payment Date:", extension_payment.paid_at.strftime("%B %d, %Y") if extension_payment.paid_at else 'N/A'],
        ["Status:", extension_payment.status.upper() if extension_payment.status else 'N/A'],
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

    # Student Information Table
    story.append(Paragraph("Student Information", heading_style))
    student_data = [
        ["Name:", f"{booking.student.first_name} {booking.student.last_name}"],
        ["Email:", booking.student.email],
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

    # Accommodation Info Table
    story.append(Paragraph("Accommodation Details", heading_style))
    accom_data = [
        ["Hostel Name:", booking.room.hostel.name],
        ["Room Number:", booking.room.room_number],
        ["Room Type:", booking.room.room_type],
        ["Previous Checkout:", booking.start_date.strftime("%B %d, %Y") if booking.start_date else 'N/A'],
        ["New Checkout:", booking.end_date.strftime("%B %d, %Y") if booking.end_date else 'N/A'],
    ]
    accom_table = Table(accom_data, colWidths=[1.5*inch, 4.5*inch])
    accom_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.lightgrey),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('BACKGROUND', (1, 0), (1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black)
    ]))
    story.append(accom_table)
    story.append(Spacer(1, 20))
    
    # Payment Details
    story.append(Paragraph("Payment Details", heading_style))
    
    # Calculate extension details
    platform_fee = get_platform_fee(db)
    monthly_rent = booking.room.price_per_month
    payment_data = [
        ["Monthly Rent:", f"MWK {monthly_rent:.2f}"],
        ["Platform Fee:", f"MWK {platform_fee:.2f}"],
        ["Total Extension Amount:", f"MWK {extension_payment.amount:.2f}"],
        ["Payment Method:", extension_payment.payment_method],
        ["Transaction ID:", extension_payment.transaction_id or "N/A"],
    ]
    pay_table = Table(payment_data, colWidths=[2*inch, 4*inch])
    pay_table.setStyle(TableStyle([
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
    story.append(pay_table)
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
    support = '<font size="9" color="gray">kernelsoft1@gmail.com | +265 883 271 664</font>'
    gen_time = f'<font size="9" color="gray">Generated by Palevel - {datetime.now().strftime('%B %d, %Y %H:%M:%S')}</font>'
    for html in [footer_brand, support, gen_time]:
        story.append(Paragraph(html, normal_style))
    story.append(Spacer(1, 3))
    disclaimer = '<font size="8" color="gray">This receipt is generated electronically and is valid without signature.</font>'
    story.append(Paragraph(disclaimer, normal_style))
    
    # Build PDF
    doc.build(story)
    
    # Get PDF bytes
    buffer.seek(0)
    pdf_bytes = buffer.getvalue()
    buffer.close()
    
    # Return PDF response
    filename = f"extension_receipt_{booking.booking_id.hex[:8]}.pdf"
    
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename={filename}",
            "Content-Length": str(len(pdf_bytes))
        }
    )
