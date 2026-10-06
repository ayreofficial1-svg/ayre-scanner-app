# Ayre legal pack: notes for the Research Analyst

Not legal advice. Have a securities lawyer or compliance professional read the final text before release.

## A. Placeholders to fill

All in `lib/legal/legal_config.dart`, except the monthly complaint figures (see end of list). Search for `[` inside `lib/legal/` before release.

| Item | Where used |
|---|---|
| RA name, SEBI reg. no., validity, RAASB enlistment, NISM certificate, address, phone, e-mail | Terms, Disclosures, Privacy |
| Grievance e-mail and phone | Grievance screen, Terms |
| RAASB complaint e-mail (copy from RAASB's site) | Grievance screen |
| Privacy contact e-mail | Privacy, Grievance |
| Jurisdiction city | Terms |
| Fee statement | Terms, MITC |
| Weekly Report scope statement | Terms, Risk |
| Holdings practice, compensation statement, disciplinary history, AI-use statement, other registrations | Disclosures |
| Hosting region | Privacy |
| "Last updated" date | All documents |
| Monthly complaint table (`_complaintMonth`, `_complaintRows`) | `grievance_screen.dart` (update every month) |

Also set `RA_REG_NUMBER` in the backend environment. The RA screen shows that value from `/api/compliance`, and it must match `kRaRegistrationNumber`.

## B. Compliance points in the current implementation

1. **Weekly Report.** The backend docstring calls it a list of stocks "manually confirmed were profitable". If losses (stop-loss hits) are left out, that is selective performance display and risks breaching SEBI's advertisement and fair-presentation rules. Show every closed recommendation. Then say so in `kWeeklyReportScope`.
2. **Options in the Weekly Report.** Entries can carry labels like "BUY SEP 2960 CE". Confirm that your RA registration and current SEBI rules allow you to publish derivative recommendations. Also confirm that the disclosures SEBI expects for them are in place. I could not confirm this from a primary source.
3. **Content of each signal.** A signal currently carries a rationale, entry, target, stop and date added. Check against SEBI's current requirements whether each recommendation must also show:
   - the time and date of publication,
   - a time horizon,
   - your holding or financial interest in the stock.
   Add these fields to the signal if so. The pack describes your practice generically.
4. **Records.** The scanner writes signal logs to local files such as `logs/` and the `app_*.json` files. SEBI requires records to be kept for 5 years. On Railway the disk is not persistent by default, so attach a volume or back the files up. Keep the written basis for every recommendation as well.
5. **Investor Charter and MITC wording.** I could not open the SEBI PDFs. The text is built from the SEBI charter and MITC as reproduced by other RA firms. Replace both with the verbatim wording from SEBI circulars CIR/2025/81 (2 June 2025, charter) and CIR/2025/20 (17 Feb 2025, MITC), or the latest version. Also verify:
   - the 21-day complaint period,
   - the SEBI helpline numbers,
   - `scores.sebi.gov.in` and `smartodr.in`,
   - the ₹1,51,000 fee cap and the one-quarter advance-fee limit.
6. **Other SEBI requirements to check.** I found no primary source for these:
   - any rule on a designated e-mail domain or phone number for RAs,
   - the exact wording of required disclosures in research reports,
   - the current trading-restriction windows (30 days before and 5 days after publication, per SEBI's July 2025 FAQs, secondary source).
7. **Account deletion.** There is no in-app way to delete an account. App stores generally want one when users create accounts in the app. Here the operator creates accounts, so an e-mail route is described. Consider adding a "Request account deletion" row.
8. **DPDP timing.** The DPDP Rules were notified on 13 Nov 2025. Most Data Fiduciary duties start on 14 May 2027, and MeitY has proposed bringing this forward to 13 Nov 2026. The policy is already written to the final requirements. Confirm the current dates.

## C. Backend settings that the legal text relies on

- Set `SCANNER_ADMIN_USERS`. If it is unset, any logged-in user can write signals and notes.
- Set `FLASK_SECRET_KEY`, and `SESSION_COOKIE_SECURE=true`.
- Remove the hard-coded fallback index levels in `_get_market_snapshot`. They can show stale numbers as live, which conflicts with the data statements in the Terms and Risk Disclosure.
- Credentials sit in plaintext in `SCANNER_USERS`, and there is no login rate limiting. The Privacy Policy says "reasonable safeguards", so fix these.
- `google_fonts` downloads fonts from Google at run time. The Privacy Policy mentions this. Bundling the fonts removes the need for that line.
- The `applicationId` is still `com.example.ayre_scanner`.

## D. Strategy confidentiality

Public text says only that research combines "rule-based screening of price and volume data" with the RA's review. No indicator, period or threshold is named. Two leaks to check:

- The admin site served at `/` has its JavaScript bundle at `static/assets/index-*.js`. That bundle contains "SMA44" and "MACD".
- Do not write the method into the free-text signal rationale.

SEBI still requires a documented rationale for each recommendation. Keep the detailed basis in private records, and write a short plain-language rationale in the app.

## E. What is not covered

- No client agreement, KYC or onboarding form (these happen outside the app).
- No cookie banner, because the mobile app uses none beyond the session cookie.
- No E-commerce or Consumer Protection (E-Commerce) Rules section, because the app sells nothing.
- I did not add an arbitration clause. A one-sided one would conflict with the "right against coercive, unfair and one-sided clauses" in the Investor Charter.
