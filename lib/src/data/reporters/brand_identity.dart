import 'dart:io';

class BrandIdentity {
  static const appName = 'Semantics Checker';
  static const reportTitle = 'Semantics Identifier Audit Report';
  static const tagline = 'Flutter semantics identifier audit CLI';

  static const reportLogoFileName = 'semantics_checker_logo.svg';

  static const reportLogoSvg =
      r'''<svg width="96" height="96" viewBox="0 0 96 96" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Semantics Checker">
<defs>
<linearGradient id="sc-surface" x1="16" y1="10" x2="78" y2="86" gradientUnits="userSpaceOnUse">
<stop stop-color="#38BDF8"/>
<stop offset="0.5" stop-color="#2563EB"/>
<stop offset="1" stop-color="#0F172A"/>
</linearGradient>
<linearGradient id="sc-accent" x1="32" y1="34" x2="72" y2="74" gradientUnits="userSpaceOnUse">
<stop stop-color="#A7F3D0"/>
<stop offset="1" stop-color="#34D399"/>
</linearGradient>
</defs>
<path d="M48 7L78 19V41C78 61 65 78 48 86C31 78 18 61 18 41V19L48 7Z" fill="url(#sc-surface)"/>
<path d="M39 35L30 44L39 53" stroke="#E0F2FE" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M57 35L66 44L57 53" stroke="#E0F2FE" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M39 62L46 69L63 50" stroke="url(#sc-accent)" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="48" cy="44" r="6" fill="#E0F2FE"/>
<circle cx="48" cy="44" r="2.6" fill="#2563EB"/>
</svg>''';

  static Future<void> writeReportLogo(String dirPath) async {
    await File('$dirPath/$reportLogoFileName').writeAsString(reportLogoSvg);
  }
}
