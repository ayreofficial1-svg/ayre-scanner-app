/// The ONE place to fill in the details only the Research Analyst can supply.
///
/// Every legal screen reads from here. Nothing in this file is invented: each
/// value is a clearly marked placeholder in square brackets, in capitals.
/// Replace the text between the quotes, keeping the quotes. Before release,
/// search the project for `[` inside lib/legal/ to be sure none are left.
///
/// Ayre is operated by an individual SEBI-registered Research Analyst (a sole
/// proprietor), not by a company or LLP, and the wording of every document is
/// written on that basis.
library;

// ── Identity ────────────────────────────────────────────────────────────────

/// Full name exactly as it appears on the SEBI registration certificate.
const String kRaName = '[RA FULL NAME AS ON SEBI CERTIFICATE]';

/// The name the service is offered under. "Ayre" is the name used in the app;
/// confirm it is the name you are entitled to use as the RA's trade name.
const String kBrandName = 'Ayre';

/// SEBI registration number (INH…). The Research Analyst screen shows the value
/// served by the backend (`RA_REG_NUMBER` environment variable); keep both
/// identical.
const String kRaRegistrationNumber = '[SEBI REGISTRATION NO. INH_________]';

/// Validity of the registration, as shown on the certificate / SEBI intermediary
/// listing (for example a date, or "Perpetual").
const String kRaRegistrationValidity = '[REGISTRATION VALIDITY]';

/// Enlistment with the Research Analyst Administration and Supervisory Body
/// (RAASB), the body appointed by SEBI for RA administration and supervision.
const String kRaasbEnlistment = '[RAASB ENLISTMENT NO. / DETAILS]';

/// NISM Research Analyst certification: number and validity.
const String kNismCertification = '[NISM CERTIFICATE NO. AND VALIDITY]';

/// Registered office / address of the Research Analyst.
const String kRaAddress = '[REGISTERED ADDRESS OF THE RESEARCH ANALYST]';

// ── Contacts ────────────────────────────────────────────────────────────────

/// General contact e-mail for the Research Analyst.
const String kRaEmail = '[RA CONTACT E-MAIL]';

/// Contact telephone number (registered with SEBI).
const String kRaPhone = '[RA CONTACT PHONE NUMBER]';

/// E-mail on which investor complaints are received. This is the first step of
/// the grievance process.
const String kGrievanceEmail = '[GRIEVANCE E-MAIL ADDRESS]';

/// Telephone number for complaints (optional but recommended).
const String kGrievancePhone = '[GRIEVANCE PHONE NUMBER]';

/// Person who handles privacy requests. For an individual RA this is normally
/// the Research Analyst. Keep as the RA's name unless someone else is appointed.
const String kPrivacyContactName = kRaName;

/// E-mail for privacy / data requests.
const String kPrivacyEmail = '[PRIVACY / DATA REQUESTS E-MAIL]';

/// RAASB e-mail address for complaint escalation. Copy the current address
/// from RAASB's website; it is not reproduced here to avoid showing a stale one.
const String kRaasbComplaintEmail = '[RAASB COMPLAINT E-MAIL — COPY FROM RAASB WEBSITE]';

// ── Terms details ───────────────────────────────────────────────────────────

/// City whose courts have jurisdiction (for example where the RA is based).
const String kJurisdictionCity = '[CITY FOR COURT JURISDICTION]';

/// What users pay, if anything, and how. Fees are not collected inside the app.
/// Examples of what to state: "Access is provided free of charge." or the fee,
/// billing period and payment channel. Individual / HUF fees are capped by SEBI
/// at ₹1,51,000 per family per annum (verify the current cap on SEBI's site).
const String kFeeStatement = '[STATE FEES, BILLING PERIOD AND PAYMENT CHANNEL — OR "No fee is charged for access to the app."]';

/// Whether the Weekly Report lists every recommendation closed in the period.
/// Complete this honestly before release (see LEGAL_NOTES.md, item 1).
const String kWeeklyReportScope =
    '[STATE WHETHER THE WEEKLY REPORT INCLUDES EVERY RECOMMENDATION CLOSED DURING THE WEEK]';

// ── Disclosures that depend on the RA's own circumstances ──────────────────

/// Holdings / financial interest practice, for example how and where the RA
/// discloses any holding in a stock recommended.
const String kHoldingsDisclosure =
    '[DESCRIBE HOW THE RA DISCLOSES ANY HOLDING OR FINANCIAL INTEREST IN A RECOMMENDED STOCK]';

/// Compensation from companies covered. State the true position.
const String kCompensationDisclosure =
    '[STATE WHETHER THE RA OR ASSOCIATES HAVE RECEIVED ANY COMPENSATION FROM A COMPANY COVERED IN THE PAST 12 MONTHS]';

/// Disciplinary history with SEBI or any regulator or exchange. State "None."
/// if there is none.
const String kDisciplinaryHistory = '[STATE DISCIPLINARY HISTORY, OR "None."]';

/// Use of artificial intelligence in producing research. The scanner in the
/// supplied code is rule-based software and uses no machine learning, but only
/// the RA can confirm this for the whole research process.
const String kAiDisclosure =
    '[CONFIRM AND STATE: e.g. "No artificial intelligence or machine-learning tool is used to generate recommendations."]';

/// Other SEBI registrations held by the RA (for example as an Investment
/// Adviser). State "None." if none.
const String kOtherRegistrations = '[STATE ANY OTHER SEBI REGISTRATIONS, OR "None."]';

// ── Hosting / data ──────────────────────────────────────────────────────────

/// Where the backend servers are hosted (country / region), for the privacy
/// notice.
const String kHostingRegion = '[HOSTING REGION OF THE BACKEND SERVERS]';

// ── Document dates ──────────────────────────────────────────────────────────

/// "Last updated" line shown on every document.
const String kLegalLastUpdated = '[DD MONTH YYYY]';
