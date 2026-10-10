/// Resolves a company logo asset path for a stock symbol, so
/// `AyreInstrumentTile` can show one wherever a stock's symbol/name is
/// displayed — falling back to its existing offline monogram whenever a
/// symbol has no bundled logo.
///
/// ## Why this exists
/// This used to resolve logos at runtime from a free third-party lookup
/// service (`AllInvestView`, with a `Logo.dev` fallback). That has been
/// replaced with a fixed set of logo images shipped inside the app itself
/// (`assets/logos/`, one PNG per NSE trading symbol, covering Nifty 500 +
/// Sensex 30 + Bank Nifty). There is no network call, no cache, and no
/// rate limit to manage any more — a symbol either has a bundled logo or it
/// doesn't, and that never changes between app runs.
///
/// ## Correctness over coverage
/// [_bundledSymbols] is the exact, closed set of trading symbols this app
/// ships a logo image for (see `assets/logos/`). A symbol not in that set
/// falls straight through to `AyreInstrumentTile`'s monogram — there is no
/// approximate or fuzzy matching, so a tile never shows the wrong company's
/// logo.
///
/// ## API compatibility
/// [peek], [resolve], and [reportBroken] keep the exact same signatures the
/// old network-backed version had, so `AyreInstrumentTile` and every other
/// call site needed no changes. [resolve] still returns a `Future<String>`
/// even though the lookup is now synchronous, purely so existing callers
/// (`.then(...)`) keep working unmodified.
class StockLogoService {
  const StockLogoService._();

  /// Folder under `assets/` these logos are bundled from. Must match the
  /// `assets/logos/` entry declared in `pubspec.yaml`.
  static const String _logosDir = 'assets/logos';

  /// NSE trading symbols this app ships a bundled `assets/logos/<symbol>.png`
  /// for (Nifty 500 + Sensex 30 + Bank Nifty, as supplied). Generated once
  /// from the contents of `assets/logos/` — regenerate this set (a simple
  /// `ls assets/logos | sed 's/\.png$//'`) whenever logo files are added or
  /// removed, so it always matches what's actually bundled.
  static const Set<String> _bundledSymbols = {
    '360ONE', '3MINDIA', 'AADHARHFC', 'AARTIIND', 'AAVAS', 'ABB', 'ABBOTINDIA',
    'ABCAPITAL', 'ABDL', 'ABFRL', 'ABLBL', 'ABSLAMC', 'ACC', 'ACE',
    'ACMESOLAR', 'ACUTAAS', 'ADANIENSOL', 'ADANIENT', 'ADANIGREEN',
    'ADANIPOWER', 'AEGISLOG', 'AEGISVOPAK', 'AFCONS', 'AFFLE', 'AIAENG',
    'AIIL', 'AJANTPHARM', 'ALKEM', 'AMBER', 'AMBUJACEM', 'ANGELONE', 'ANTHEM',
    'ANURAS', 'APARINDS', 'APLAPOLLO', 'APOLLOHOSP', 'APOLLOTYRE', 'APTUS',
    'ASAHIINDIA', 'ASHOKLEY', 'ASIANPAINT', 'ASTERDM', 'ASTRAL', 'ATGL',
    'ATHERENERG', 'ATUL', 'AUBANK', 'AUROPHARMA', 'AXISBANK', 'BAJAJ-AUTO',
    'BAJAJFINSV', 'BAJAJHLDNG', 'BALKRISIND', 'BALRAMCHIN', 'BANDHANBNK',
    'BANKBARODA', 'BANKINDIA', 'BATAINDIA', 'BAYERCROP', 'BBTC', 'BDL', 'BEL',
    'BELRISE', 'BEML', 'BERGEPAINT', 'BHARATFORG', 'BHARTIARTL', 'BHARTIHEXA',
    'BHEL', 'BIKAJI', 'BIOCON', 'BLS', 'BLUEDART', 'BLUEJET', 'BLUESTARCO',
    'BOSCHLTD', 'BPCL', 'BRIGADE', 'BRITANNIA', 'BSE', 'BSOFT', 'CAMS',
    'CANBK', 'CANFINHOME', 'CAPLIPOINT', 'CARBORUNIV', 'CARTRADE',
    'CASTROLIND', 'CCL', 'CDSL', 'CEATLTD', 'CEMPRO', 'CENTRALBK', 'CESC',
    'CGPOWER', 'CHALET', 'CHAMBLFERT', 'CHENNPETRO', 'CHOLAFIN', 'CHOLAHLDNG',
    'CIEINDIA', 'CIPLA', 'COALINDIA', 'COCHINSHIP', 'COFORGE', 'COLPAL',
    'CONCOR', 'CONCORDBIO', 'COROMANDEL', 'CRAFTSMAN', 'CREDITACC', 'CRISIL',
    'CROMPTON', 'CUB', 'CUMMINSIND', 'CYIENT', 'DABUR', 'DALBHARAT',
    'DATAPATTNS', 'DCMSHRIRAM', 'DEEPAKFERT', 'DEEPAKNTR', 'DELHIVERY',
    'DEVYANI', 'DIVISLAB', 'DIXON', 'DLF', 'DMART', 'DOMS', 'DRREDDY',
    'ECLERX', 'EICHERMOT', 'EIDPARRY', 'EIHOTEL', 'ELECON', 'ELGIEQUIP',
    'EMAMILTD', 'EMCURE', 'EMMVEE', 'ENDURANCE', 'ENGINERSIN', 'ENRIN', 'ERIS',
    'ESCORTS', 'ETERNAL', 'EXIDEIND', 'FACT', 'FEDERALBNK', 'FINCABLES',
    'FIRSTCRY', 'FIVESTAR', 'FLUOROCHEM', 'FORCEMOT', 'FORTIS', 'FSL', 'GAIL',
    'GALLANTT', 'GESHIP', 'GICRE', 'GILLETTE', 'GLAND', 'GLAXO', 'GLENMARK',
    'GMDCLTD', 'GMRAIRPORT', 'GODFRYPHLP', 'GODIGIT', 'GODREJCP', 'GODREJIND',
    'GODREJPROP', 'GPIL', 'GRANULES', 'GRAPHITE', 'GRASIM', 'GRAVITA', 'GROWW',
    'GRSE', 'GVT&D', 'HAL', 'HAVELLS', 'HBLENGINE', 'HCLTECH', 'HDBFS',
    'HDFCAMC', 'HDFCBANK', 'HDFCLIFE', 'HEROMOTOCO', 'HEXT', 'HFCL',
    'HINDALCO', 'HINDCOPPER', 'HINDPETRO', 'HINDUNILVR', 'HINDZINC',
    'HOMEFIRST', 'HONASA', 'HSCL', 'HUDCO', 'HYUNDAI', 'ICICIAMC', 'ICICIBANK',
    'ICICIGI', 'ICICIPRULI', 'IDBI', 'IDFCFIRSTB', 'IEX', 'IFCI', 'IGIL',
    'IGL', 'IIFL', 'INDGN', 'INDHOTEL', 'INDIACEM', 'INDIAMART', 'INDIANB',
    'INDIGO', 'INDUSINDBK', 'INDUSTOWER', 'INFY', 'INOXWIND', 'INTELLECT',
    'IOB', 'IOC', 'IPCALAB', 'IRB', 'IRCON', 'IRCTC', 'IREDA', 'IRFC', 'ITC',
    'ITCHOTELS', 'ITI', 'J&KBANK', 'JBMA', 'JINDALSAW', 'JINDALSTEL', 'JIOFIN',
    'JKCEMENT', 'JKTYRE', 'JMFINANCIL', 'JPPOWER', 'JSL', 'JSWCEMENT',
    'JSWENERGY', 'JSWINFRA', 'JSWSTEEL', 'JUBLFOOD', 'JUBLINGREA',
    'JUBLPHARMA', 'JWL', 'JYOTICNC', 'KAJARIACER', 'KALYANKJIL', 'KARURVYSYA',
    'KAYNES', 'KEC', 'KEI', 'KFINTECH', 'KIMS', 'KIRLOSENG', 'KOTAKBANK',
    'KPIL', 'KPITTECH', 'KPRMILL', 'LALPATHLAB', 'LATENTVIEW', 'LAURUSLABS',
    'LEMONTREE', 'LGEINDIA', 'LICHSGFIN', 'LICI', 'LINDEINDIA', 'LLOYDSME',
    'LODHA', 'LT', 'LTFOODS', 'LTM', 'LTTS', 'LUPIN', 'M&M', 'MAHABANK',
    'MANAPPURAM', 'MANKIND', 'MAPMYINDIA', 'MARICO', 'MARUTI', 'MAXHEALTH',
    'MAZDOCK', 'MCX', 'MEDANTA', 'MEESHO', 'MFSL', 'MGL', 'MINDACORP', 'MMTC',
    'MOTHERSON', 'MOTILALOFS', 'MPHASIS', 'MRF', 'MRPL', 'MSUMI', 'NATCOPHARM',
    'NATIONALUM', 'NAUKRI', 'NAVINFLUOR', 'NBCC', 'NCC', 'NESTLEIND', 'NETWEB',
    'NEULANDLAB', 'NEWGEN', 'NH', 'NHPC', 'NIACL', 'NIVABUPA', 'NLCINDIA',
    'NMDC', 'NSLNISP', 'NTPC', 'NTPCGREEN', 'NUVAMA', 'NYKAA', 'OBEROIRLTY',
    'OIL', 'OLAELEC', 'OLECTRA', 'ONGC', 'PAGEIND', 'PARADEEP', 'PATANJALI',
    'PAYTM', 'PCBL', 'PERSISTENT', 'PETRONET', 'PFC', 'PFIZER', 'PFOCUS',
    'PGEL', 'PHOENIXLTD', 'PIDILITIND', 'PIIND', 'PNB', 'PNBHOUSING',
    'POLICYBZR', 'POLYCAB', 'POLYMED', 'POONAWALLA', 'POWERGRID', 'POWERINDIA',
    'PPLPHARMA', 'PRESTIGE', 'PVRINOX', 'RADICO', 'RAILTEL', 'RAINBOW',
    'RAMCOCEM', 'RBLBANK', 'RECLTD', 'REDINGTON', 'RELIANCE', 'RHIM', 'RITES',
    'RKFORGE', 'RPOWER', 'RRKABEL', 'RVNL', 'SAGILITY', 'SAILIFE',
    'SAMMAANCAP', 'SAPPHIRE', 'SARDAEN', 'SAREGAMA', 'SBFC', 'SBICARD',
    'SBILIFE', 'SBIN', 'SCHAEFFLER', 'SCHNEIDER', 'SCI', 'SHREECEM', 'SIEMENS',
    'SIGNATURE', 'SJVN', 'SOBHA', 'SOLARINDS', 'SONACOMS', 'SONATSOFTW',
    'SPLPETRO', 'SRF', 'STARHEALTH', 'SUMICHEM', 'SUNPHARMA', 'SUPREMEIND',
    'SUZLON', 'SWIGGY', 'SYNGENE', 'SYRMA', 'TARIL', 'TATACAP', 'TATACHEM',
    'TATACOMM', 'TATACONSUM', 'TATAELXSI', 'TATAINVEST', 'TATAPOWER',
    'TATASTEEL', 'TATATECH', 'TBOTEK', 'TCS', 'TECHM', 'TECHNOE', 'TENNIND',
    'THERMAX', 'TIINDIA', 'TIMKEN', 'TITAGARH', 'TITAN', 'TMCV', 'TMPV',
    'TORNTPHARM', 'TORNTPOWER', 'TRENT', 'TRIDENT', 'TRITURBINE', 'TTML',
    'TVSMOTOR', 'UBL', 'UCOBANK', 'ULTRACEMCO', 'UNIONBANK', 'UNITDSPR',
    'UNOMINDA', 'UPL', 'USHAMART', 'UTIAMC', 'VBL', 'VEDL', 'VIJAYA', 'VOLTAS',
    'VTL', 'WAAREEENER', 'WELCORP', 'WHIRLPOOL', 'WIPRO', 'WOCKPHARMA',
    'YESBANK', 'ZEEL', 'ZENSARTECH', 'ZENTEC', 'ZYDUSLIFE', 'ZYDUSWELL',
  };

  /// Bundled logos that are white (or near-white) artwork on a transparent
  /// background. On the default white plate they would vanish, so the tile
  /// backs them with a dark plate. Found by scanning `assets/logos/`; every
  /// other transparent logo is dark or coloured, and every opaque one brings
  /// its own background.
  static const Set<String> _lightArtwork = {
    'ASTRAL', 'AXISBANK', 'EMBASSY', 'INDHOTEL', 'JSWCEMENT', 'LEMONTREE',
    'TATASTEEL',
  };

  /// Whether [symbol]'s logo needs a dark plate behind it to stay legible.
  static bool needsDarkPlate(String symbol) =>
      _lightArtwork.contains(_key(symbol));

  /// Resolved answers, keyed by upper-cased symbol: an `assets/logos/...`
  /// path, or `''` for "no bundled logo". Since [_bundledSymbols] never
  /// changes at runtime, this is really just a memo of string concatenation
  /// — kept mainly so [peek] has an O(1) answer to return.
  static final Map<String, String> _memory = {};

  static String _key(String symbol) => symbol.trim().toUpperCase();

  /// Whatever is already known about [symbol] without doing any work: an
  /// asset path, `''` if there's confidently no logo, or null if [resolve]
  /// hasn't been called for this symbol yet.
  ///
  /// `AyreInstrumentTile` checks this first so a symbol resolved earlier
  /// (e.g. on Home) shows its logo immediately, with no flicker, when the
  /// same symbol appears again elsewhere.
  static String? peek(String symbol) => _memory[_key(symbol)];

  /// Resolves [symbol] to an `assets/logos/...` path, or `''` if this app
  /// doesn't bundle a logo for it. [name] is accepted for API compatibility
  /// with the previous lookup-based implementation but is unused — matching
  /// is by NSE trading symbol only now, since the logo set is closed and
  /// exact rather than searched.
  static Future<String> resolve(String symbol, {String? name}) async {
    final key = _key(symbol);
    final cached = _memory[key];
    if (cached != null) return cached;

    final path = _bundledSymbols.contains(key) ? '$_logosDir/$key.png' : '';
    _memory[key] = path;
    return path;
  }

  /// Called by `AyreInstrumentTile` when a resolved logo asset fails to
  /// actually decode/load. Downgrades the cached answer to "no logo" so the
  /// tile falls back to its monogram immediately and stops retrying the
  /// same asset on every rebuild. Shouldn't normally trigger — every path
  /// this returns is a real, bundled asset — but kept as a safety net in
  /// case a logo file is ever missing or corrupt at build time.
  static void reportBroken(String symbol) {
    _memory[_key(symbol)] = '';
  }
}
