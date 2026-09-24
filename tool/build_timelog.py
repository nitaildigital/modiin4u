"""Builds the Modiin4u time log workbook.

Dates, hours and the work described come from the repository's own history,
so the log starts from what actually happened rather than from memory. Later
days are added by hand in the same shape.
"""

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

OUT = "Modiin4u_Time_Log.xlsx"

NAVY = "123A72"
MID_BLUE = "1E40B5"
LIGHT = "E8EEF7"
BAND = "F7F9FC"
GREY = "878787"
BORDER = "D9D9D9"

FONT = "Arial"

thin = Side(style="thin", color=BORDER)
box = Border(left=thin, right=thin, top=thin, bottom=thin)

# ── The log: date, day, area, what was done, hours, status ──
# Hours are the working span on the day, rounded to the half hour.
ENTRIES = [
    ("2026-08-11", "Setup", "Project set up; 24 screens scaffolded across events, real estate, community, deals, games, steps, parking and admin", 4.0, "Done"),
    ("2026-08-12", "App shell", "Onboarding, search, dark mode, community feed; real estate rebuilt from Figma; auth screens and map", 6.0, "Done"),
    ("2026-08-28", "Admin panel", "Admin dashboard built out — 23 sections with their screens; analytics dashboard; images on articles and businesses", 5.0, "Done"),
    ("2026-09-14", "Web + screens", "Web production pages: homepage, real estate, listing detail. New screens for auth, restaurants, events map. Platform configs, icons, splash", 7.0, "Done"),
    ("2026-09-15", "Web", "Real estate search for sale and rent, web layout", 3.0, "Done"),
    ("2026-09-16", "Content import", "Directory, news, restaurants and map pulled from the WordPress export; desktop pages for deals, events, news, municipal; shared navbar and footer", 8.0, "Done"),
    ("2026-09-18", "Content import", "Every article bundled and every category exposed", 3.0, "Done"),
    ("2026-09-20", "Database", "SQL seed generated from the WordPress export", 3.0, "Done"),
    ("2026-09-23", "Live data", "News, businesses, restaurants, events, map and search moved onto the live database — 200 businesses and 659 articles with their photographs", 4.0, "Done"),
    ("2026-09-23", "App quality", "Loading states matched to the real layout; back button fixed across the app; scrolling freed to the screen's full refresh rate; fonts bundled instead of downloaded", 2.0, "Done"),
    ("2026-09-23", "Accounts", "Sign-in, sign-up, forgot and change password on Supabase; account deletion; notification preferences; access controls; saved favourites", 3.0, "Done"),
    ("2026-09-23", "Maps", "Google Maps on the client's key, with the app's own markers; key kept out of the repository", 1.5, "Done"),
    ("2026-09-23", "Admin panel", "Control centre moved onto live data — 21 sections; opening hours editor; category picker; image upload; safe delete", 4.0, "Done"),
    ("2026-09-23", "Database", "Migrations for security, sign-in, notifications, media storage and the real estate schema", 2.0, "Done"),
    ("2026-09-23", "Languages", "Hebrew and English with a working switch; sign-in and settings translated", 1.5, "Done"),
]

STATUSES = ["Done", "In progress", "Blocked", "On hold"]


def build() -> None:
    wb = Workbook()

    # ══════════════════════════════════════════════════════
    # Time log
    # ══════════════════════════════════════════════════════
    ws = wb.active
    ws.title = "Time Log"

    ws["A1"] = "Modiin4u — Time Log"
    ws["A1"].font = Font(name=FONT, size=16, bold=True, color=NAVY)
    ws.merge_cells("A1:F1")

    ws["A2"] = "Arvindra Singh · GTS Infosoft"
    ws["A2"].font = Font(name=FONT, size=10, color=GREY)
    ws.merge_cells("A2:F2")

    headers = ["Date", "Day", "Area", "Work done", "Hours", "Status"]
    widths = [12, 11, 16, 78, 8, 13]

    for col, (head, width) in enumerate(zip(headers, widths), start=1):
        cell = ws.cell(row=4, column=col, value=head)
        cell.font = Font(name=FONT, size=11, bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor=NAVY)
        cell.alignment = Alignment(horizontal="center", vertical="center")
        cell.border = box
        ws.column_dimensions[get_column_letter(col)].width = width

    row = 5
    for date, area, work, hours, status in ENTRIES:
        ws.cell(row=row, column=1, value=date)
        # The weekday is derived, so a corrected date corrects itself.
        ws.cell(row=row, column=2, value=f'=IF(A{row}="","",TEXT(A{row},"ddd"))')
        ws.cell(row=row, column=3, value=area)
        ws.cell(row=row, column=4, value=work)
        ws.cell(row=row, column=5, value=hours)
        ws.cell(row=row, column=6, value=status)

        banded = (row % 2 == 1)
        for col in range(1, 7):
            c = ws.cell(row=row, column=col)
            c.font = Font(name=FONT, size=10)
            c.border = box
            c.alignment = Alignment(
                horizontal="left" if col in (3, 4) else "center",
                vertical="top",
                wrap_text=(col == 4),
            )
            if banded:
                c.fill = PatternFill("solid", fgColor=BAND)

        ws.cell(row=row, column=1).number_format = "yyyy-mm-dd"
        ws.cell(row=row, column=5).number_format = "0.0"
        row += 1

    # Blank rows to carry on in, so the shape is obvious.
    first_blank = row
    for _ in range(40):
        ws.cell(row=row, column=2, value=f'=IF(A{row}="","",TEXT(A{row},"ddd"))')
        for col in range(1, 7):
            c = ws.cell(row=row, column=col)
            c.font = Font(name=FONT, size=10)
            c.border = box
            c.alignment = Alignment(
                horizontal="left" if col in (3, 4) else "center",
                vertical="top",
                wrap_text=(col == 4),
            )
            if row % 2 == 1:
                c.fill = PatternFill("solid", fgColor=BAND)
        ws.cell(row=row, column=1).number_format = "yyyy-mm-dd"
        ws.cell(row=row, column=5).number_format = "0.0"
        row += 1

    last = row - 1

    # ── Total ──
    total_row = last + 2
    ws.cell(row=total_row, column=4, value="Total hours")
    ws.cell(row=total_row, column=4).font = Font(name=FONT, size=11, bold=True, color=NAVY)
    ws.cell(row=total_row, column=4).alignment = Alignment(horizontal="right")

    total = ws.cell(row=total_row, column=5, value=f"=SUM(E5:E{last})")
    total.font = Font(name=FONT, size=11, bold=True, color=NAVY)
    total.fill = PatternFill("solid", fgColor=LIGHT)
    total.border = box
    total.number_format = "0.0"
    total.alignment = Alignment(horizontal="center")

    # ── Status as a dropdown, so the column stays consistent ──
    dv = DataValidation(
        type="list",
        formula1='"' + ",".join(STATUSES) + '"',
        allow_blank=True,
        showDropDown=False,
    )
    ws.add_data_validation(dv)
    dv.add(f"F5:F{last}")

    ws.freeze_panes = "A5"
    ws.auto_filter.ref = f"A4:F{last}"

    # ── A note on how to use it ──
    note = total_row + 2
    ws.cell(row=note, column=1, value="How to use")
    ws.cell(row=note, column=1).font = Font(name=FONT, size=10, bold=True, color=NAVY)

    for i, line in enumerate([
        "Add one row per block of work. Type the date in column A — the day fills in by itself.",
        "Hours are in decimals: 90 minutes is 1.5.",
        "Status is a dropdown: Done, In progress, Blocked, On hold.",
        "The summary tab adds itself up from this one — nothing to keep in step by hand.",
    ], start=1):
        c = ws.cell(row=note + i, column=1, value=line)
        c.font = Font(name=FONT, size=9, color=GREY)
        ws.merge_cells(start_row=note + i, start_column=1, end_row=note + i, end_column=6)

    # ══════════════════════════════════════════════════════
    # Summary
    # ══════════════════════════════════════════════════════
    sm = wb.create_sheet("Summary")

    sm["A1"] = "Summary"
    sm["A1"].font = Font(name=FONT, size=16, bold=True, color=NAVY)
    sm.merge_cells("A1:C1")

    sm["A3"] = "By area"
    sm["A3"].font = Font(name=FONT, size=12, bold=True, color=MID_BLUE)

    for col, (head, width) in enumerate(
        zip(["Area", "Hours", "Share"], [26, 12, 12]), start=1
    ):
        c = sm.cell(row=4, column=col, value=head)
        c.font = Font(name=FONT, size=11, bold=True, color="FFFFFF")
        c.fill = PatternFill("solid", fgColor=NAVY)
        c.alignment = Alignment(horizontal="center")
        c.border = box
        sm.column_dimensions[get_column_letter(col)].width = width

    areas = sorted({e[1] for e in ENTRIES})
    r = 5
    for area in areas:
        sm.cell(row=r, column=1, value=area)
        sm.cell(
            row=r, column=2,
            value=f"=SUMIF('Time Log'!$C${5}:$C${last},A{r},'Time Log'!$E${5}:$E${last})",
        )
        sm.cell(
            row=r, column=3,
            value=f"=IF($B${5 + len(areas) + 1}=0,0,B{r}/$B${5 + len(areas) + 1})",
        )
        for col in range(1, 4):
            c = sm.cell(row=r, column=col)
            c.font = Font(name=FONT, size=10)
            c.border = box
            c.alignment = Alignment(horizontal="left" if col == 1 else "center")
        sm.cell(row=r, column=2).number_format = "0.0"
        sm.cell(row=r, column=3).number_format = "0.0%"
        r += 1

    tr = r + 1
    sm.cell(row=tr, column=1, value="Total")
    sm.cell(row=tr, column=2, value=f"=SUM(B5:B{r - 1})")
    sm.cell(row=tr, column=3, value=f"=IF(B{tr}=0,0,1)")
    for col in range(1, 4):
        c = sm.cell(row=tr, column=col)
        c.font = Font(name=FONT, size=11, bold=True, color=NAVY)
        c.fill = PatternFill("solid", fgColor=LIGHT)
        c.border = box
        c.alignment = Alignment(horizontal="left" if col == 1 else "center")
    sm.cell(row=tr, column=2).number_format = "0.0"
    sm.cell(row=tr, column=3).number_format = "0.0%"

    # ── By day ──
    dr = tr + 3
    sm.cell(row=dr, column=1, value="By day")
    sm.cell(row=dr, column=1).font = Font(name=FONT, size=12, bold=True, color=MID_BLUE)

    for col, head in enumerate(["Date", "Hours", "Entries"], start=1):
        c = sm.cell(row=dr + 1, column=col, value=head)
        c.font = Font(name=FONT, size=11, bold=True, color="FFFFFF")
        c.fill = PatternFill("solid", fgColor=NAVY)
        c.alignment = Alignment(horizontal="center")
        c.border = box

    days = sorted({e[0] for e in ENTRIES})
    d = dr + 2
    for day in days:
        sm.cell(row=d, column=1, value=day)
        sm.cell(
            row=d, column=2,
            value=f"=SUMIF('Time Log'!$A${5}:$A${last},A{d},'Time Log'!$E${5}:$E${last})",
        )
        sm.cell(
            row=d, column=3,
            value=f"=COUNTIF('Time Log'!$A${5}:$A${last},A{d})",
        )
        for col in range(1, 4):
            c = sm.cell(row=d, column=col)
            c.font = Font(name=FONT, size=10)
            c.border = box
            c.alignment = Alignment(horizontal="center")
        sm.cell(row=d, column=1).number_format = "yyyy-mm-dd"
        sm.cell(row=d, column=2).number_format = "0.0"
        d += 1

    sm.cell(row=d + 1, column=1,
            value="Both tables read the Time Log tab, so adding a row there updates them.")
    sm.cell(row=d + 1, column=1).font = Font(name=FONT, size=9, color=GREY)
    sm.merge_cells(start_row=d + 1, start_column=1, end_row=d + 1, end_column=3)

    wb.save(OUT)
    print(f"wrote {OUT} — {len(ENTRIES)} entries, rows 5..{last}")


if __name__ == "__main__":
    build()
