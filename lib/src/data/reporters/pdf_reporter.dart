import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/semantics_issue.dart';
import '../../domain/entities/fixed_semantics_item.dart';
import 'brand_identity.dart';

class PdfReporter {
  static Future<void> generate(
    List<SemanticsIssue> issues,
    List<FixedSemanticsItem> fixedList,
    String dirPath,
  ) async {
    final pdf = pw.Document();
    await BrandIdentity.writeReportLogo(dirPath);
    final logoWidget = _buildLogoMark();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    logoWidget,
                    pw.SizedBox(width: 8),
                    pw.Text(
                      BrandIdentity.reportTitle.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1E3A8A'),
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  DateTime.now().toLocal().toString().substring(0, 19),
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 15),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Confidential - Automation Testing Report',
                  style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey500,
                      fontStyle: pw.FontStyle.italic),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Title Band / Header Card
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                gradient: const pw.LinearGradient(
                  colors: [
                    PdfColor.fromInt(0xff1e3a8a),
                    PdfColor.fromInt(0xff2563eb)
                  ],
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${BrandIdentity.appName} Quality Audit Metrics',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'This report validates semantics identifier coverage on interactive Flutter components to keep automation and accessibility standards production-ready.',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.blue100,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Statistics Grid (3 Columns)
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FEF2F2'),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#FCA5A5'), width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('REMAINING ISSUES',
                            style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#991B1B'))),
                        pw.SizedBox(height: 4),
                        pw.Text('${issues.length}',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#991B1B'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#EFF6FF'),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#BFDBFE'), width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('AFFECTED FILES',
                            style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#1E40AF'))),
                        pw.SizedBox(height: 4),
                        pw.Text('${_groupIssuesByFile(issues).length}',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#1E40AF'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0FDF4'),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#86EFAC'), width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FIXED IN BRANCH',
                            style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#166534'))),
                        pw.SizedBox(height: 4),
                        pw.Text('${fixedList.length}',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#166534'))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Fixed Semantics List
            if (fixedList.isNotEmpty) ...[
              pw.Text(
                'v Fixed Semantics in this Branch',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#166534'),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColor.fromHex('#DCFCE7'), width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),
                  1: const pw.FixedColumnWidth(35),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: PdfColor.fromHex('#DCFCE7')),
                    children: [
                      _buildHeaderCell('No', PdfColor.fromHex('#166534')),
                      _buildHeaderCell('Line', PdfColor.fromHex('#166534')),
                      _buildHeaderCell(
                          'File Path', PdfColor.fromHex('#166534')),
                      _buildHeaderCell('Widget', PdfColor.fromHex('#166534')),
                      _buildHeaderCell(
                          'Semantics Identifier', PdfColor.fromHex('#166534')),
                    ],
                  ),
                  for (int i = 0; i < fixedList.length; i++)
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: i % 2 == 0
                            ? PdfColors.white
                            : PdfColor.fromHex('#F0FDF4'),
                      ),
                      children: [
                        _buildTableCell('${i + 1}'),
                        _buildTableCell('${fixedList[i].line}'),
                        _buildTableCell(fixedList[i].file),
                        _buildTableCell(fixedList[i].widget),
                        _buildTableCell(fixedList[i].identifier, isBold: true),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Remaining Issues Grouped by File
            if (issues.isNotEmpty) ...[
              pw.Text(
                'x Remaining Issues requiring Action',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#991B1B'),
                ),
              ),
              pw.SizedBox(height: 8),
              for (final group in _groupIssuesByFile(issues)) ...[
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F9'),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('📄 ', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        group.filePath,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1E293B'),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColor.fromHex('#F1F5F9'), width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(35),
                    1: const pw.FixedColumnWidth(110),
                    2: const pw.FixedColumnWidth(140),
                    3: const pw.FlexColumnWidth(),
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                          pw.BoxDecoration(color: PdfColor.fromHex('#FEF2F2')),
                      children: [
                        _buildHeaderCell('Line', PdfColor.fromHex('#991B1B')),
                        _buildHeaderCell('Widget', PdfColor.fromHex('#991B1B')),
                        _buildHeaderCell(
                            'Suggested ID', PdfColor.fromHex('#991B1B')),
                        _buildHeaderCell(
                            'Code Snippet', PdfColor.fromHex('#991B1B')),
                      ],
                    ),
                    for (int i = 0; i < group.issues.length; i++)
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: i % 2 == 0
                              ? PdfColors.white
                              : PdfColor.fromHex('#FAFAFA'),
                        ),
                        children: [
                          _buildTableCell('${group.issues[i].line}'),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#EFF6FF'),
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(3)),
                              ),
                              child: pw.Text(
                                group.issues[i].widgetName,
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#1D4ED8'),
                                ),
                              ),
                            ),
                          ),
                          _buildTableCell(group.issues[i].suggestion,
                              isGreenText: true),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(4),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#0F172A'),
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4)),
                              ),
                              child: pw.Text(
                                group.issues[i].codeSnippet,
                                style: pw.TextStyle(
                                  fontSize: 6.5,
                                  font: pw.Font.courier(),
                                  color: PdfColor.fromHex('#E2E8F0'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],
            ],
          ];
        },
      ),
    );

    final file = File('$dirPath/report.pdf');
    await file.writeAsBytes(await pdf.save());
    print('\x1B[1;32m✓ PDF report created: $dirPath/report.pdf\x1B[0m');
  }

  static pw.Widget _buildLogoMark() {
    return pw.Container(
      width: 32,
      height: 32,
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [
            PdfColor.fromInt(0xff38bdf8),
            PdfColor.fromInt(0xff2563eb),
            PdfColor.fromInt(0xff0f172a),
          ],
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Center(
        child: pw.Text(
          'SC',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildHeaderCell(String text, PdfColor textColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isBold = false, bool isGreenText = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isGreenText ? PdfColors.green800 : PdfColors.black,
        ),
      ),
    );
  }

  static List<_IssueGroup> _groupIssuesByFile(List<SemanticsIssue> issues) {
    final Map<String, List<SemanticsIssue>> map = {};
    for (final issue in issues) {
      map.putIfAbsent(issue.filePath, () => []).add(issue);
    }
    return map.entries
        .map((e) => _IssueGroup(filePath: e.key, issues: e.value))
        .toList();
  }
}

class _IssueGroup {
  final String filePath;
  final List<SemanticsIssue> issues;

  _IssueGroup({required this.filePath, required this.issues});
}
