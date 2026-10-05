import 'legal_config.dart';

/// One headed block of a legal document.
class LegalSection {
  const LegalSection({
    this.heading,
    this.paragraphs = const [],
    this.bullets = const [],
    this.closing = const [],
  });

  final String? heading;

  /// Paragraphs shown before the bullets.
  final List<String> paragraphs;

  /// Bulleted points.
  final List<String> bullets;

  /// Paragraphs shown after the bullets.
  final List<String> closing;
}

/// A complete legal document rendered by `LegalDocumentScreen`.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.sections,
    this.intro,
    this.showLastUpdated = true,
  });

  final String title;
  final String? intro;
  final List<LegalSection> sections;
  final bool showLastUpdated;
}

/// The statement SEBI expects every registered intermediary to carry.
const String kSebiRegistrationDisclaimer =
    'Registration granted by SEBI, enlistment with RAASB and certification '
    'from NISM in no way guarantee the performance of the Research Analyst or '
    'provide any assurance of returns to investors.';

/// The standard market-risk statement.
const String kMarketRiskStatement =
    'Investments in the securities market are subject to market risks. Read all '
    'the related documents carefully before investing.';

// ════════════════════════════════════════════════════════════════════════════
// TERMS AND CONDITIONS
// ════════════════════════════════════════════════════════════════════════════

final LegalDocument kTermsDocument = LegalDocument(
  title: 'Terms and Conditions',
  intro:
      'These Terms and Conditions govern your use of the $kBrandName app and '
      'the research content in it. Please read them with the Risk Disclosure, '
      'the Most Important Terms and Conditions (MITC) and the Privacy Policy, '
      'all available under Legal in your Profile. By creating an account, signing in or using the '
      'app you confirm that you have read and accepted them.',
  sections: [
    LegalSection(
      heading: '1. Who provides this service',
      paragraphs: [
        '$kBrandName is operated by $kRaName, an individual registered with '
            'the Securities and Exchange Board of India (SEBI) as a Research '
            'Analyst under the SEBI (Research Analysts) Regulations, 2014, '
            'registration number $kRaRegistrationNumber. In these Terms, '
            '“the Research Analyst”, “the RA” and “Ayre” mean that individual '
            'acting as sole proprietor of the $kBrandName service. '
            'No company, LLP or partnership is involved.',
        'Registered address: $kRaAddress. Contact: $kRaEmail, $kRaPhone.',
      ],
    ),
    LegalSection(
      heading: '2. What the app provides',
      paragraphs: ['The app is a research service. It gives you:'],
      bullets: [
        'Signals: research recommendations on listed Indian equities, each '
            'with a short rationale and, where published, indicative entry, '
            'exit (target) and stop-loss price levels, a direction (bullish or '
            'bearish) and the date it was added.',
        'Weekly Report: a record of recommendations that were closed during a '
            'week, showing entry and exit prices, the outcome (target or '
            'stop-loss) and the resulting return per share.',
        'Insights: market information such as index levels, top gainers, top '
            'losers, most active stocks, volatility, momentum and volume '
            'readings, a market-breadth based sentiment indicator, and short '
            'market notes.',
        'Learn: educational articles about markets and investing.',
        'Alerts: in-app and push notifications about new signals and other '
            'messages from the Research Analyst.',
      ],
    ),
    LegalSection(
      heading: '3. What the app does not provide',
      bullets: [
        'The app does not execute trades, place orders, hold money or '
            'securities, or operate your trading or demat account. The '
            'Research Analyst cannot carry out any trade on your behalf.',
        'The app is not a broker, a portfolio manager or an investment '
            'adviser, and does not provide personalised investment advice. '
            'Research is published for all users alike and is not prepared '
            'for your personal financial situation, goals or risk appetite.',
        'The app does not offer, and the Research Analyst does not promise, '
            'any assured, guaranteed or fixed return, or any risk-free '
            'investment. Such schemes are prohibited by law.',
        'The Research Analyst will never ask you for the login credentials or '
            'OTPs of your trading, demat or bank account, or for money to be '
            'transferred to the Research Analyst for investing.',
      ],
    ),
    LegalSection(
      heading: '4. Eligibility and your account',
      bullets: [
        'You must be an adult (18 or over) and legally able to enter into a '
            'contract in India.',
        'You create your own account in the app with your name, e-mail '
            'address and a password, and sign in with your e-mail and '
            'password. Give accurate details. Your password is personal to '
            'you; do not share it. You are responsible for activity under '
            'your account.',
        'Verifying your e-mail address is requested but is not currently '
            'required to use the app. This may change, in which case the app '
            'will tell you.',
        'Tell the Research Analyst promptly if you think your account has '
            'been compromised, change your password, and keep your contact '
            'details up to date.',
        'The app is intended for use in India and concerns securities listed '
            'on Indian exchanges.',
      ],
    ),
    LegalSection(
      heading: '5. How to use the research',
      paragraphs: [
        'Recommendations are one input to your own decision. Before acting you '
            'should read the rationale, consider your own objectives, '
            'finances and risk tolerance, and where needed take advice from a '
            'qualified professional. Any investment you make is your own '
            'decision and at your own risk.',
        'Price levels shown with a signal (entry, exit/target, stop-loss) are '
            'indicative research levels, not orders and not promises that the '
            'price will reach them. Markets can gap, halt or hit circuit '
            'limits, so a stop-loss may not be executed at the level shown.',
      ],
    ),
    LegalSection(
      heading: '6. Signals, updates and withdrawal',
      bullets: [
        'A signal is shown only while it is active. The Research Analyst may '
            'change, close, withdraw or replace a signal at any time, and an '
            'updated or withdrawn signal may not always be accompanied by a '
            'notification. Check the app before you act.',
        'The date shown against a signal is the date it was added to the app. '
            'Prices move after publication, so a level that was reasonable '
            'when published may no longer be.',
        'Notifications depend on your device, network and settings and may be '
            'delayed or not delivered. Do not rely on a notification alone.',
      ],
    ),
    LegalSection(
      heading: '7. Weekly Report and past results',
      paragraphs: [
        'The Weekly Report records recommendations that were closed in the '
            'period shown, with entry and exit prices and outcomes as recorded '
            'by the Research Analyst. $kWeeklyReportScope',
        'Returns shown are per share, before brokerage, taxes, charges and '
            'slippage, and do not represent what any user earned. Past results '
            'are not an indication of future performance. See the Risk '
            'Disclosure for more.',
      ],
    ),
    LegalSection(
      heading: '8. Market data and third-party content',
      paragraphs: [
        'Prices, index levels, movers, breadth and similar data come from '
            'third-party market data sources and are processed automatically. '
            'They may be delayed, incomplete, revised or wrong, and are shown '
            'for information only. Do not use them as the sole basis for a '
            'trade. Company logos are bundled with the app with attribution to '
            'AllInvestView.',
      ],
    ),
    LegalSection(
      heading: '9. Fees',
      paragraphs: [
        kFeeStatement,
        'No payment is collected inside the app. Any fee is paid only through '
            'banking channels (cheque, online bank transfer, UPI and similar); '
            'cash is not accepted. Fees for individual and HUF clients are '
            'subject to the limits set by SEBI. See the MITC for details.',
      ],
    ),
    LegalSection(
      heading: '10. Acceptable use and confidentiality of content',
      paragraphs: [
        'Research is provided for your own use. You must not:',
      ],
      bullets: [
        'copy, forward, publish, sell or share signals, reports or other app '
            'content with others, including on social media or messaging '
            'groups;',
        'present the content as your own research or use it to offer research '
            'or advisory services to others;',
        'attempt to access accounts, systems or data you are not authorised '
            'to use, interfere with the app or its servers, or reverse '
            'engineer the app or its backend;',
        'use automated tools to scrape or collect content from the app.',
      ],
    ),
    LegalSection(
      heading: '11. Intellectual property',
      paragraphs: [
        'The app, its design, software, research content and the $kBrandName '
            'name and mark belong to the Research Analyst or its licensors and '
            'are protected by law. You receive a personal, non-exclusive, '
            'non-transferable right to view the content in the app for your '
            'own use for as long as your access continues. Third-party names, '
            'logos and data remain the property of their owners.',
      ],
    ),
    LegalSection(
      heading: '12. Suspension and ending access',
      paragraphs: [
        'You may stop using the app at any time and may ask for your account to '
            'be closed (see the Privacy Policy). The Research Analyst may '
            'suspend or end access if these Terms are breached, if required by '
            'law or a regulator, or if the service is changed or discontinued. '
            'Where fees have been paid for a period not yet delivered, any '
            'refund will follow the terms agreed with you and applicable SEBI '
            'requirements.',
      ],
    ),
    LegalSection(
      heading: '13. Liability',
      paragraphs: [
        'Investments in securities are subject to market risk, and losses can '
            'result from following or not following any recommendation. To the '
            'extent permitted by law, the Research Analyst is not liable for '
            'losses that arise from market movements, from your investment '
            'decisions, or from delays, interruptions or errors in data, '
            'networks, devices or third-party services outside the Research '
            'Analyst’s reasonable control.',
        'Nothing in these Terms excludes or limits liability for fraud or '
            'wilful misconduct, or any duty or liability the Research Analyst '
            'has under the SEBI Act, the SEBI (Research Analysts) Regulations, '
            '2014 or other law that cannot lawfully be excluded, and nothing '
            'here limits your right to complain to SEBI or to seek remedies '
            'before the appropriate forum.',
        'The service is provided on an “as available” basis. The Research '
            'Analyst does not guarantee that the app will be uninterrupted or '
            'error-free.',
      ],
    ),
    LegalSection(
      heading: '14. Privacy',
      paragraphs: [
        'How personal data is handled is set out in the Privacy Policy, which '
            'forms part of these Terms.',
      ],
    ),
    LegalSection(
      heading: '15. Complaints and dispute resolution',
      paragraphs: [
        'If you have a complaint, first write to the Research Analyst at '
            '$kGrievanceEmail. The Research Analyst will try to resolve it '
            'quickly and in any case within the period SEBI prescribes. If you '
            'are not satisfied you can escalate through SEBI’s SCORES portal '
            'and the SMART ODR (online dispute resolution) portal. The '
            'Grievance Redressal screen under Legal gives the full steps. '
            'Nothing in these Terms prevents you from using these routes.',
      ],
    ),
    LegalSection(
      heading: '16. Governing law',
      paragraphs: [
        'These Terms are governed by the laws of India. Subject to the '
            'dispute resolution routes above and to any right you have to '
            'approach a consumer or other forum with jurisdiction over you, '
            'the courts at $kJurisdictionCity have jurisdiction.',
      ],
    ),
    LegalSection(
      heading: '17. Changes to these Terms',
      paragraphs: [
        'The Terms may be updated, for example when the law or SEBI’s '
            'requirements change or the service changes. The date of the '
            'latest version is shown at the top. Material changes will be '
            'notified in the app. If you keep using the app after a change, '
            'you accept the updated Terms; if you do not agree, stop using the '
            'app and ask for your account to be closed.',
      ],
    ),
    LegalSection(
      heading: '18. Contact',
      paragraphs: [
        '$kRaName, $kRaAddress. E-mail $kRaEmail. Phone $kRaPhone.',
      ],
    ),
  ],
);

// ════════════════════════════════════════════════════════════════════════════
// MITC
// ════════════════════════════════════════════════════════════════════════════

final LegalDocument kMitcDocument = LegalDocument(
  title: 'Most Important Terms and Conditions',
  intro:
      'These are the most important terms of the research service, set out '
      'as SEBI requires Research Analysts to disclose them to clients. They '
      'apply alongside the full Terms and Conditions. If anything here '
      'differs from the Terms and Conditions, this document and SEBI’s '
      'requirements prevail.',
  sections: [
    LegalSection(
      bullets: [
        '1. These terms and the consent given to them are for the research '
            'services provided by the Research Analyst (RA). The RA cannot '
            'execute or carry out any trade (purchase or sale) on behalf of '
            'the client.',
        '2. The RA’s fee is subject to the ceiling prescribed by SEBI, '
            'presently ₹1,51,000 per annum per family of client for all '
            'research services, excluding statutory charges. This ceiling '
            'applies to individual and HUF clients. Fee for this service: '
            '$kFeeStatement',
        '3. The RA may charge fees in advance if the client agrees. Advance '
            'fees cannot exceed the period SEBI stipulates, presently one '
            'quarter.',
        '4. Fees may be paid by cheque, online bank transfer, UPI and similar '
            'banking channels. Cash payment is not allowed. Payment may also '
            'be made through the CeFCoM mechanism available through BSE '
            'Limited, if the client so chooses.',
        '5. The RA must comply with SEBI regulations on the disclosure and '
            'mitigation of any actual or potential conflict of interest.',
        '6. Assured, guaranteed or fixed-return schemes and similar schemes '
            'are prohibited by law. No such scheme is offered.',
        '7. The RA cannot guarantee returns, profits, accuracy or risk-free '
            'investments from the use of the RA’s research services.',
        '8. Investments made on the basis of recommendations in research '
            'reports are subject to market risks. Losses from market '
            'movements do not give rise to a claim against the RA merely '
            'because a recommendation did not work.',
        '9. SEBI registration, enlistment with RAASB and NISM certification '
            'do not guarantee the RA’s performance or assure any returns to '
            'the client.',
        '10. For any grievance, first contact the RA. If it is not resolved, '
            'approach SEBI’s SCORES portal or the SMART ODR portal. See '
            'Grievance Redressal.',
        '11. The client should keep contact details with the RA up to date.',
        '12. The RA will never ask for the client’s login credentials or OTPs '
            'for the client’s trading account, demat account or bank '
            'account.',
      ],
    ),
  ],
);

// ════════════════════════════════════════════════════════════════════════════
// RISK DISCLOSURE
// ════════════════════════════════════════════════════════════════════════════

final LegalDocument kRiskDocument = LegalDocument(
  title: 'Risk Disclosure',
  intro: '$kMarketRiskStatement $kSebiRegistrationDisclaimer',
  sections: [
    LegalSection(
      heading: 'Market risk',
      paragraphs: [
        'The value of securities rises and falls. You can lose some or all of '
            'the money you invest, and in leveraged products such as futures '
            'and options you can lose more than you put in. Invest only money '
            'you can afford to lose.',
      ],
    ),
    LegalSection(
      heading: 'Signals are research, not certainty',
      bullets: [
        'A signal is the Research Analyst’s view at the time it was added. It '
            'may prove wrong. No method of analysis, however carefully '
            'applied, predicts markets reliably.',
        'Entry, exit (target) and stop-loss levels are indicative. The price '
            'may never reach an entry or target level, or may move through '
            'it quickly.',
        'A stop-loss limits risk only if it is executed. Gaps at the open, '
            'trading halts, circuit limits, low liquidity and fast markets '
            'can cause execution far from the level shown, with larger '
            'losses than planned.',
        'Signals are general research and are not matched to your '
            'circumstances. A stock that suits one investor may not suit '
            'another.',
        'Positions concentrated in few stocks, or taken without following '
            'the stop-loss, carry greater risk.',
      ],
    ),
    LegalSection(
      heading: 'Derivatives (futures and options)',
      paragraphs: [
        'Some entries in the Weekly Report may describe trades in options or '
            'other derivatives. Derivatives are leveraged and complex, can '
            'lose value very quickly, and options can expire worthless. SEBI’s '
            'own studies have found that a large majority of individual '
            'traders in equity derivatives incurred net losses. A derivative '
            'trade described in the app is not an offer or invitation to '
            'trade it, and may not suit you.',
      ],
    ),
    LegalSection(
      heading: 'Weekly Report and past results',
      bullets: [
        'The Weekly Report shows results of past recommendations. Past '
            'performance is not indicative of future results.',
        'Figures are per share and before brokerage, taxes, charges and '
            'slippage. Your own results would differ depending on when and '
            'at what price you entered and exited, and whether you acted at '
            'all.',
        'The Weekly Report covers the period shown only and does not '
            'represent the return of any user, portfolio or strategy.',
        kWeeklyReportScope,
      ],
    ),
    LegalSection(
      heading: 'Historical and back-tested information',
      paragraphs: [
        'The Research Analyst may test ideas on historical data. Such tests '
            'are hypothetical: they are built with hindsight, ignore costs '
            'and the effect of real-time trading, and do not represent actual '
            'trading. Historical or back-tested results, if ever shown, are '
            'not actual performance and are no guide to future results.',
      ],
    ),
    LegalSection(
      heading: 'Market data and indicators',
      bullets: [
        'Prices, index levels, gainers, losers, volume, volatility and '
            'momentum readings come from third parties and are computed '
            'automatically. They can be delayed or wrong, and may be '
            'unavailable at times.',
        'The sentiment indicator is a statistic based on how many stocks in '
            'a broad set of listed companies are rising or falling. It '
            'describes what has happened, not what will happen, and is not a '
            'recommendation.',
        'Market notes and educational articles are general information and '
            'are not recommendations to buy or sell.',
      ],
    ),
    LegalSection(
      heading: 'Technology risk',
      paragraphs: [
        'Apps, networks, servers and third-party services can fail or be '
            'delayed. Notifications may arrive late or not at all, and the '
            'content you see may be out of date. Always check the current '
            'position before acting.',
      ],
    ),
    LegalSection(
      heading: 'Other risks',
      bullets: [
        'Liquidity risk: you may be unable to sell at a fair price or at all.',
        'Company and sector risk: results, news, regulation or fraud can '
            'change a stock’s value suddenly.',
        'Tax and costs: brokerage, taxes and other charges reduce returns.',
        'Behavioural risk: acting on tips, rumours or fear of missing out '
            'often leads to losses. Beware of anyone who guarantees returns.',
      ],
    ),
    LegalSection(
      heading: 'Protect yourself',
      bullets: [
        'Deal only with SEBI-registered intermediaries and check the '
            'registration on SEBI’s website.',
        'Never share your trading, demat or bank passwords or OTPs. Never '
            'give money to a Research Analyst for investing.',
        'Report any assured-return offer to SEBI.',
      ],
    ),
  ],
);

// ════════════════════════════════════════════════════════════════════════════
// RESEARCH ANALYST DISCLOSURES
// ════════════════════════════════════════════════════════════════════════════

final LegalDocument kDisclosuresDocument = LegalDocument(
  title: 'Research Analyst disclosures',
  showLastUpdated: true,
  sections: [
    LegalSection(
      heading: 'Registration',
      bullets: [
        'Research Analyst: $kRaName',
        'SEBI registration number: $kRaRegistrationNumber',
        'Validity: $kRaRegistrationValidity',
        'RAASB enlistment: $kRaasbEnlistment',
        'NISM certification: $kNismCertification',
        'Address: $kRaAddress',
        'Contact: $kRaEmail, $kRaPhone',
        'Other SEBI registrations: $kOtherRegistrations',
      ],
      closing: [kSebiRegistrationDisclaimer, kMarketRiskStatement],
    ),
    LegalSection(
      heading: 'Nature of the business',
      paragraphs: [
        'The Research Analyst publishes research reports and recommendations '
            'on listed securities. The Research Analyst does not execute '
            'trades, hold client money or securities, or manage portfolios, '
            'and is not a broker or investment adviser through this app.',
      ],
    ),
    LegalSection(
      heading: 'How research is produced',
      paragraphs: [
        'Recommendations come from the Research Analyst’s own research '
            'process. It combines rule-based screening of price and volume '
            'data of listed Indian equities with the Research Analyst’s '
            'review and judgement, and recommendations are published only '
            'after that review. The detailed parameters are proprietary and '
            'are not published. Each recommendation carries a rationale, and '
            'the Research Analyst keeps a record of the basis for it as SEBI '
            'requires.',
        'Research is based on publicly available information and market data. '
            'Recommendations are made independently and are not influenced by '
            'any company covered.',
      ],
    ),
    LegalSection(
      heading: 'Use of artificial intelligence',
      paragraphs: [kAiDisclosure],
    ),
    LegalSection(
      heading: 'Financial interest and conflicts of interest',
      paragraphs: [
        'The Research Analyst, and persons associated with the Research '
            'Analyst, may hold or may have held positions in, or may have '
            'traded in, securities mentioned in the app. $kHoldingsDisclosure',
        'The Research Analyst follows SEBI’s conflict-of-interest and '
            'trading-restriction requirements for research analysts, which '
            'include restrictions on dealing in a security around the '
            'publication of research on it. The Research Analyst aims to '
            'identify, disclose and avoid or manage conflicts of interest.',
        kCompensationDisclosure,
      ],
    ),
    LegalSection(
      heading: 'Disciplinary history',
      paragraphs: [kDisciplinaryHistory],
    ),
    LegalSection(
      heading: 'Records, audit and fairness',
      paragraphs: [
        'The Research Analyst maintains the records SEBI requires, including '
            'the rationale for recommendations and records of client '
            'communications, and is subject to the annual audit and periodic '
            'reporting SEBI requires of research analysts. Research is '
            'distributed to all users without discrimination, and the '
            'Research Analyst does not selectively give advance information '
            'to any user.',
      ],
    ),
    LegalSection(
      heading: 'Performance information',
      paragraphs: [
        'Information about past recommendations is shown only as a record '
            'of those recommendations. It is not an advertisement of future '
            'returns, a guarantee, or a measure of what you would earn. See '
            'the Risk Disclosure.',
      ],
    ),
    LegalSection(
      heading: 'Not investment advice',
      paragraphs: [
        'Nothing in the app is a personalised recommendation or a '
            'representation that any investment or strategy suits your '
            'circumstances, and nothing in it is legal, tax or accounting '
            'advice. It is not an offer or solicitation to buy or sell '
            'securities.',
      ],
    ),
  ],
);

// ════════════════════════════════════════════════════════════════════════════
// INVESTOR CHARTER
// ════════════════════════════════════════════════════════════════════════════

final LegalDocument kInvestorCharterDocument = LegalDocument(
  title: 'Investor Charter',
  intro:
      'Investor Charter for Research Analysts, based on the charter '
      'prescribed by SEBI.',
  sections: [
    LegalSection(
      heading: 'Vision',
      paragraphs: ['Invest with knowledge and safety.'],
    ),
    LegalSection(
      heading: 'Mission',
      paragraphs: [
        'Every investor should be able to access the products and services '
            'suited to them, manage and monitor their investments to meet '
            'their goals, receive the research they are entitled to, and '
            'attain financial wellness.',
      ],
    ),
    LegalSection(
      heading: 'Business transacted by a Research Analyst',
      bullets: [
        'Publish research reports based on research activities.',
        'Provide an independent and unbiased view on securities.',
        'Offer unbiased recommendations, disclosing financial interests.',
        'Base research recommendations on analysis of publicly available '
            'information.',
        'Conduct an audit annually.',
        'Ensure that all advertisements adhere to the Advertisement Code.',
        'Maintain records of interactions with clients.',
      ],
    ),
    LegalSection(
      heading: 'Services provided to investors',
      bullets: [
        'Onboard clients, share the terms and conditions and complete KYC.',
        'Disclose material information, disciplinary history and conflicts '
            'of interest.',
        'Disclose the extent of use of artificial intelligence tools in '
            'providing research services.',
        'Distribute research reports without discrimination.',
        'Maintain confidentiality of a research report until it is '
            'published.',
        'Protect the privacy of client data.',
        'Provide service timelines and adhere to them.',
        'Offer guidance on complex and high-risk products.',
        'Treat all clients with honesty and integrity, and keep client '
            'information confidential except where law requires otherwise.',
      ],
    ),
    LegalSection(
      heading: 'Rights of investors',
      bullets: [
        'Right to privacy and confidentiality.',
        'Right to transparent practices.',
        'Right to fair and equitable treatment.',
        'Right to adequate information.',
        'Right to initial and continuing disclosure.',
        'Right to statutory and regulatory disclosures.',
        'Right to fair advertising.',
        'Right to awareness of service parameters and turnaround times.',
        'Right to timely grievance redressal.',
        'Right to exit from the service as per the agreed terms.',
        'Right to guidance on complex and high-risk products.',
        'Right to accessibility for differently abled persons.',
        'Right to give feedback.',
        'Right against coercive, unfair and one-sided clauses.',
      ],
    ),
    LegalSection(
      heading: 'Responsibilities of investors: do’s',
      bullets: [
        'Deal only with SEBI-registered Research Analysts.',
        'Check that the Research Analyst has a valid registration '
            'certificate and note the SEBI registration number.',
        'Pay attention to the disclosures made.',
        'Pay only through banking channels and keep signed receipts.',
        'Review recommendations before you trade.',
        'Ask all relevant questions and clear your doubts.',
        'Seek clarification on complex products.',
        'Know your right to discontinue the service and to give feedback.',
        'Reject clauses that are not compliant with regulations.',
        'Report offers of guaranteed returns to SEBI.',
      ],
    ),
    LegalSection(
      heading: 'Responsibilities of investors: don’ts',
      bullets: [
        'Do not provide funds for investment to the Research Analyst.',
        'Do not fall for misleading advertisements, rumours or tips.',
        'Do not be swayed by limited-period discounts or incentive offers.',
        'Do not share login credentials or passwords.',
      ],
    ),
    LegalSection(
      heading: 'Grievance redressal',
      paragraphs: [
        'Approach the Research Analyst first. The Research Analyst will '
            'strive to resolve the grievance immediately and not later than '
            '21 days from receipt. If it is not resolved, you can escalate '
            'to SEBI’s SCORES portal and use the SMART ODR portal for online '
            'conciliation or arbitration. The Grievance Redressal screen '
            'under Legal gives contacts and steps.',
      ],
    ),
  ],
);

// ════════════════════════════════════════════════════════════════════════════
// PRIVACY POLICY
// ════════════════════════════════════════════════════════════════════════════

final LegalDocument kPrivacyDocument = LegalDocument(
  title: 'Privacy Policy',
  intro:
      'This policy explains what personal data the $kBrandName app handles, '
      'why, who sees it, how long it is kept, and the choices and rights you '
      'have. It is written to meet India’s Digital Personal Data Protection '
      'Act, 2023 and the rules made under it, as they come into force, and '
      'other applicable Indian law.',
  sections: [
    LegalSection(
      heading: '1. Who is responsible',
      paragraphs: [
        '$kRaName, an individual SEBI-registered Research Analyst '
            '($kRaRegistrationNumber) operating $kBrandName as a sole '
            'proprietor, decides why and how your personal data is handled '
            'and is the “Data Fiduciary”. Address: $kRaAddress.',
        'Privacy contact: $kPrivacyContactName, $kPrivacyEmail.',
      ],
    ),
    LegalSection(
      heading: '2. What data is handled',
      paragraphs: ['The app is designed to collect as little as possible.'],
      bullets: [
        'Account data: the name, e-mail address and password you give when '
            'you register. Accounts are provided by Google Firebase '
            'Authentication. Your password is stored by Firebase in '
            'protected form; the Research Analyst and the app’s server do '
            'not see or store it. Whether your e-mail address is verified is '
            'also recorded. If you edit your profile name, the new name is '
            'saved on your account.',
        'Sign-in session: while you are signed in, the app keeps a sign-in '
            'on your device and sends a short-lived token with its requests '
            'so the server can confirm you are a signed-in user. The server '
            'reads the token but does not store your account details.',
        'E-mails from the service: Firebase sends the e-mail verification '
            'and password-reset messages you request.',
        'Notification data: if push notifications are on, your device’s '
            'Firebase Cloud Messaging token, the platform (Android or iOS), '
            'the app version, and the times it was registered and last seen. '
            'The token is stored on the server together with an internal '
            'account identifier, so notifications can be tied to a signed-in '
            'account, but not with your name or e-mail address.',
        'Data kept on your device: your settings (alerts, text size, theme), '
            'a list of alerts the app has recorded, which signals you have '
            'seen, and cached market data so screens load quickly. Alerts, '
            'seen-signal records and cached articles are cleared when you '
            'sign out or a different account signs in.',
        'Technical data: like most online services, the server and hosting '
            'provider record technical information about requests, such as '
            'IP address, time, device or app type and errors, for security '
            'and fault finding.',
        'Messages to support: anything you send when you write to the '
            'Research Analyst, such as your e-mail address and message.',
        'Client records: if you become a client of the Research Analyst, '
            'onboarding, KYC, agreement, payment and communication records '
            'are collected through the Research Analyst’s onboarding '
            'process, outside the app, and are handled under this policy '
            'and SEBI’s record-keeping requirements.',
      ],
    ),
    LegalSection(
      heading: '3. What the app does not collect',
      paragraphs: [
        'The app does not collect your location, contacts, photos, camera or '
            'microphone data, trading or demat account details, bank '
            'details, PAN or Aadhaar. It contains no advertising or '
            'analytics tracking software and does not sell personal data.',
      ],
    ),
    LegalSection(
      heading: '4. Why it is used',
      bullets: [
        'To create your account, let you sign in and use the app, and send you '
            'verification and password-reset e-mails.',
        'To deliver notifications you have chosen to receive (push token).',
        'To keep the app secure, find faults and prevent misuse (technical '
            'data).',
        'To respond to your queries and complaints.',
        'To meet legal and regulatory duties, including SEBI’s record '
            'keeping and audit requirements for research analysts.',
      ],
    ),
    LegalSection(
      heading: '5. Consent and choices',
      paragraphs: [
        'Your data is handled with your consent or for another purpose '
            'the law allows, such as complying with the law. You can '
            'switch off push notifications or new-signal alerts in Settings '
            'at any time; switching push off removes your device token from '
            'the server. Withdrawing consent may mean some features stop '
            'working, and does not affect handling that was lawful before '
            'you withdrew. You can also ask to close your account (see '
            'section 9).',
      ],
    ),
    LegalSection(
      heading: '6. Who else receives data',
      bullets: [
        'Google (Firebase Authentication) keeps your account and sends '
            'verification and password-reset e-mails.',
        'Google (Firebase Cloud Messaging) delivers push notifications and '
            'receives the device token and message content for that purpose.',
        'The hosting provider that runs the app’s servers processes data on '
            'the Research Analyst’s behalf. Servers are hosted in '
            '$kHostingRegion.',
        'The app’s fonts may be downloaded from Google’s font servers, which '
            'can see your device’s IP address when that happens.',
        'Market data providers and exchanges supply price data to the '
            'server. Your personal data is not sent to them.',
        'Regulators, courts, law-enforcement or other authorities where the '
            'law requires disclosure.',
      ],
      closing: [
        'Personal data is not sold or shared for advertising.',
      ],
    ),
    LegalSection(
      heading: '7. Transfers outside India',
      paragraphs: [
        'Some service providers, such as Google for sign-in and notifications, may '
            'process data on servers outside India. Such transfers are made '
            'only as the law permits.',
      ],
    ),
    LegalSection(
      heading: '8. How long data is kept',
      bullets: [
        'Device tokens are kept while push is on and removed when you turn '
            'push off, or when the notification service reports the token '
            'is no longer valid.',
        'Account data is kept in Firebase while your account is active. '
            'Device tokens are linked to your account identifier until they '
            'are removed as described above.',
        'Technical logs are kept only as long as needed for security and '
            'fault finding, and for any minimum period the law requires.',
        'Records the Research Analyst must keep by SEBI regulation, '
            'including client and recommendation records, are kept for the '
            'period required (currently five years) even if you ask for '
            'erasure, and are not used for other purposes.',
        'Data on your device is under your control and is removed when you '
            'clear app data or uninstall.',
      ],
    ),
    LegalSection(
      heading: '9. Your rights and how to use them',
      paragraphs: ['You may:'],
      bullets: [
        'ask for a summary of the personal data held about you and how it is '
            'used;',
        'ask for correction, completion or updating of your data;',
        'ask for erasure of your data (subject to legal retention above) and '
            'for your account to be closed;',
        'withdraw consent;',
        'nominate another person to exercise your rights if you die or '
            'become unable to act;',
        'complain about how your data is handled.',
      ],
      closing: [
        'Write to $kPrivacyEmail from the contact details you gave the '
            'Research Analyst, saying what you want. The aim is to reply '
            'within 30 days and always within the time the law allows. If '
            'you are not satisfied with the response, you may complain to '
            'the Data Protection Board of India as provided in the Digital '
            'Personal Data Protection Act, 2023, after first using this '
            'grievance route.',
      ],
    ),
    LegalSection(
      heading: '10. Security',
      paragraphs: [
        'Reasonable safeguards are used, including encrypted (HTTPS) '
            'transmission between the app and the server, restricted access '
            'to administration functions, and limiting what is collected. '
            'No system is completely secure. If a personal data breach '
            'affects you, you and the Data Protection Board will be '
            'informed as the law requires. Use a strong password that you '
            'do not use elsewhere, protect your device, and sign out on shared '
            'devices.',
      ],
    ),
    LegalSection(
      heading: '11. Children',
      paragraphs: [
        'The app is for adults. It is not directed at anyone under 18 and '
            'accounts are not created for them.',
      ],
    ),
    LegalSection(
      heading: '12. Changes to this policy',
      paragraphs: [
        'This policy may be updated when the app or the law changes. The date '
            'of the latest version is shown at the top, and material changes '
            'will be notified in the app.',
      ],
    ),
  ],
);

// ════════════════════════════════════════════════════════════════════════════
// FAQ
// ════════════════════════════════════════════════════════════════════════════

class LegalFaq {
  const LegalFaq(this.question, this.answer);
  final String question;
  final String answer;
}

final List<LegalFaq> kLegalFaqs = [
  const LegalFaq(
    'What is Ayre?',
    'Ayre is a research service run by an individual SEBI-registered '
        'Research Analyst. It publishes research recommendations on listed '
        'Indian stocks, a record of closed recommendations, market insights '
        'and learning articles.',
  ),
  LegalFaq(
    'Is the Research Analyst registered with SEBI?',
    'Yes. The registration number, validity and related details are under '
        'Legal > Research Analyst information. You can also verify them on '
        'SEBI’s website. $kSebiRegistrationDisclaimer',
  ),
  const LegalFaq(
    'Can I buy or sell stocks in the app?',
    'No. Ayre only publishes research. It does not place orders or hold '
        'your money or securities. You place any trade yourself through '
        'your own broker.',
  ),
  const LegalFaq(
    'Is a signal personal advice for me?',
    'No. Signals are general research published to all users. They are not '
        'based on your finances or risk appetite, so consider your own '
        'situation before acting.',
  ),
  const LegalFaq(
    'Are returns guaranteed?',
    'No. Nobody can guarantee returns in the securities market. Any '
        'assured-return offer is prohibited and should be reported to SEBI.',
  ),
  const LegalFaq(
    'What do entry, exit and stop-loss mean?',
    'They are indicative price levels from the research: where the idea '
        'was considered, a level where profit may be booked, and a level at '
        'which the idea is considered wrong. They are not orders, and the '
        'market may not trade at them or may jump past them.',
  ),
  const LegalFaq(
    'What is the Weekly Report?',
    'It records recommendations closed in a week, with entry and exit prices '
        'and whether the target or stop-loss was hit. Returns are per share '
        'and before costs and taxes. It shows past results only and does not '
        'indicate future performance.',
  ),
  const LegalFaq(
    'Why does the price in the app differ from my broker?',
    'Market data comes from third parties and may be delayed or differ. Use '
        'your broker’s live price before placing any order.',
  ),
  const LegalFaq(
    'Does Ayre use artificial intelligence?',
    'See Legal > Research Analyst information for the Research Analyst’s '
        'disclosure on the use of AI tools.',
  ),
  const LegalFaq(
    'What data does the app collect?',
    'Your name, e-mail address and password (held by Google Firebase '
        'Authentication), a notification token if you allow push, and basic '
        'technical logs. It does not collect your location, contacts or '
        'trading account details. Read the Privacy Policy for details and '
        'your rights.',
  ),
  const LegalFaq(
    'How do I stop notifications?',
    'Open Profile > Settings and turn off push notifications or new-signal '
        'alerts. You can also change notification permission in your phone’s '
        'settings.',
  ),
  const LegalFaq(
    'How do I close my account or have my data erased?',
    'Write to the privacy contact in the Privacy Policy. Records that SEBI '
        'regulations require the Research Analyst to keep will be retained '
        'for the required period.',
  ),
  const LegalFaq(
    'Will the Research Analyst ever ask for my passwords, OTPs or money?',
    'Never. Do not share your trading, demat or bank credentials or OTPs '
        'with anyone, and do not hand over money for investing.',
  ),
  const LegalFaq(
    'How do I make a complaint?',
    'Write to the Research Analyst first. If it is not resolved, escalate '
        'to SEBI SCORES and the SMART ODR portal. Steps and contacts are '
        'under Legal > Grievance redressal.',
  ),
];