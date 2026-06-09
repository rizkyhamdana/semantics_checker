import 'dart:io';
import '../../domain/entities/semantics_issue.dart';
import '../../domain/entities/fixed_semantics_item.dart';
import 'brand_identity.dart';

class HtmlReporter {
  static Future<void> generate(
    List<SemanticsIssue> issues,
    List<FixedSemanticsItem> fixedList,
    String dirPath,
  ) async {
    final errors = issues.where((i) => !i.isWarning).toList();
    final warnings = issues.where((i) => i.isWarning).toList();
    final statusColor = errors.isNotEmpty
        ? '#EF4444'
        : (warnings.isNotEmpty ? '#F59E0B' : '#10B981');
    final statusText = errors.isNotEmpty
        ? 'FAILED'
        : (warnings.isNotEmpty ? 'WARNINGS' : 'PASSED');
    final brandLogoSvg = BrandIdentity.reportLogoSvg;

    final Map<String, List<SemanticsIssue>> grouped = {};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.filePath, () => []).add(issue);
    }

    final sidebarErrorsHtml = StringBuffer();
    final sidebarWarningsHtml = StringBuffer();
    final filePanelsHtml = StringBuffer();

    int fileIdx = 0;
    grouped.forEach((filePath, fileIssues) {
      fileIdx++;
      final fileId = 'file-$fileIdx';

      final parts = filePath.split('/');
      final fileName = parts.last;
      final fileDir =
          parts.length > 1 ? parts.sublist(0, parts.length - 1).join('/') : '';

      final fileErrorsCount = fileIssues.where((i) => !i.isWarning).length;
      final fileWarningsCount = fileIssues.where((i) => i.isWarning).length;

      final sidebarItem = '''
      <div class="sidebar-item" id="nav-$fileId" onclick="showFile('$fileId')" data-filepath="${filePath.toLowerCase()}">
        <div class="sidebar-item-info">
          <span class="file-name">$fileName</span>
          <span class="file-dir">$fileDir</span>
        </div>
        <div style="display: flex; gap: 4px;">
          ${fileErrorsCount > 0 ? '<span class="badge-count" style="background: var(--danger-light); color: var(--danger); font-size: 0.7em;">$fileErrorsCount E</span>' : ''}
          ${fileWarningsCount > 0 ? '<span class="badge-count" style="background: #FEF3C7; color: #D97706; border: 1px solid #FDE68A; font-size: 0.7em;">$fileWarningsCount W</span>' : ''}
        </div>
      </div>
      ''';

      if (fileErrorsCount > 0) {
        sidebarErrorsHtml.write(sidebarItem);
      } else {
        sidebarWarningsHtml.write(sidebarItem);
      }

      String buildCardHtml(SemanticsIssue issue) {
        final escapedSnippet = issue.codeSnippet
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;')
            .replaceAll('\n', '<br/>')
            .replaceAll(' ', '&nbsp;');

        final suggestionBlock = issue.isWarning
            ? '''
              <div class="suggestion-wrapper" style="background: #FEF3C7; border-color: #FDE68A;">
                <span class="suggestion-prefix" style="color: #B45309;">Warning:</span>
                <span class="suggestion-val" style="color: #D97706; font-family: sans-serif;">${issue.errorMessage ?? "Menggunakan default identifier"}</span>
              </div>
              '''
            : issue.isFormatIssue 
                ? '''
                  <div class="suggestion-wrapper" style="background: var(--danger-light); border-color: #FECACA;">
                    <span class="suggestion-prefix" style="color: #DC2626;">Error:</span>
                    <span class="suggestion-val" style="color: var(--danger); font-family: sans-serif;">${issue.errorMessage}</span>
                  </div>
                  '''
                : '''
                  <div class="suggestion-wrapper">
                    <span class="suggestion-prefix">Suggest:</span>
                    <span class="suggestion-val">${issue.suggestion}</span>
                  </div>
                  ''';

        final actionButton = issue.isWarning
            ? '''
              <button class="btn-copy" onclick="copyId(event, '${issue.suggestion}')" style="color: #D97706; background: #FEF3C7;">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
                Copy ID
              </button>
              '''
            : issue.isFormatIssue 
                ? '''
                  <span class="badge-count" style="background: var(--danger-light); color: var(--danger); font-size: 0.8em; border-radius: 6px;">Perlu Diubah</span>
                  '''
                : '''
                  <button class="btn-copy" onclick="copyId(event, '${issue.suggestion}')">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
                    Copy ID
                  </button>
                  ''';

        final widgetBadgeStyle = issue.isWarning
            ? 'style="background: #FEF3C7; color: #D97706; border-color: #FDE68A;"'
            : issue.isFormatIssue
                ? 'style="background: #FFF7ED; color: #EA580C; border-color: #FED7AA;"'
                : '';

        final cardBorderClass = issue.isWarning ? 'warning' : 'error';

        return '''
        <div class="issue-card $cardBorderClass">
          <div class="issue-header" onclick="toggleIssue(this)">
            <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
              <span class="line-badge">Line ${issue.line}</span>
              <span class="widget-badge" $widgetBadgeStyle>${issue.widgetName}</span>
              $suggestionBlock
            </div>
            <div style="display: flex; align-items: center; gap: 12px;">
              $actionButton
              <span class="caret-icon">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="6 9 12 15 18 9"></polyline></svg>
              </span>
            </div>
          </div>
          <div class="issue-body">
            <div class="code-container">
              <div class="code-header">
                <span>Dart Source Code</span>
              </div>
              <div class="code-box">$escapedSnippet</div>
            </div>
          </div>
        </div>
        ''';
      }

      final fileErrors = fileIssues.where((i) => !i.isWarning).toList();
      final fileWarnings = fileIssues.where((i) => i.isWarning).toList();

      final errorsHtml = StringBuffer();
      if (fileErrors.isNotEmpty) {
        errorsHtml.write('<h3 class="section-title error-title" style="color: var(--danger); margin: 16px 0 8px 0; font-size: 1.1em; display: flex; align-items: center; gap: 8px;"><span>❌</span> Errors to Fix (${fileErrors.length})</h3>');
        errorsHtml.write('<div class="issues-list">');
        for (final issue in fileErrors) {
          errorsHtml.write(buildCardHtml(issue));
        }
        errorsHtml.write('</div>');
      }

      final warningsHtml = StringBuffer();
      if (fileWarnings.isNotEmpty) {
        warningsHtml.write('<h3 class="section-title warning-title" style="color: #D97706; margin: 24px 0 8px 0; font-size: 1.1em; display: flex; align-items: center; gap: 8px;"><span>⚠️</span> Warnings (${fileWarnings.length})</h3>');
        warningsHtml.write('<div class="issues-list">');
        for (final issue in fileWarnings) {
          warningsHtml.write(buildCardHtml(issue));
        }
        warningsHtml.write('</div>');
      }

      filePanelsHtml.write('''
      <div class="file-panel" id="panel-$fileId" style="display: none;">
        <div class="panel-header">
          <div class="panel-title-wrapper">
            <span class="panel-file-icon">📄</span>
            <div>
              <h2 class="panel-file-title">$fileName</h2>
              <span class="panel-file-path">$filePath</span>
            </div>
          </div>
          <div class="panel-actions">
            <button class="btn btn-primary" onclick="toggleAllAccordions('$fileId', true)">Expand All</button>
            <button class="btn" onclick="toggleAllAccordions('$fileId', false)">Collapse All</button>
          </div>
        </div>
        <div class="file-issues-content" style="display: flex; flex-direction: column; gap: 8px;">
          $errorsHtml
          $warningsHtml
        </div>
      </div>
      ''');
    });

    final fixedRowsHtml = StringBuffer();
    for (int i = 0; i < fixedList.length; i++) {
      final item = fixedList[i];
      fixedRowsHtml.write('''
      <tr style="border-bottom: 1px solid var(--border-color); transition: background-color 0.2s;">
        <td style="padding: 14px 16px; font-weight: 600; color: #4B5563; font-family: 'JetBrains Mono', monospace; font-size: 0.85em;">Line ${item.line}</td>
        <td style="padding: 14px 16px;"><span class="widget-badge" style="background: var(--success-light); color: var(--success); border-color: #A7F3D0;">${item.widget}</span></td>
        <td style="padding: 14px 16px; font-weight: 700; color: var(--success); font-family: 'JetBrains Mono', monospace; font-size: 0.85em;">${item.identifier}</td>
        <td style="padding: 14px 16px; color: var(--text-muted); font-size: 0.85em; word-break: break-all;">${item.file}</td>
      </tr>
      ''');
    }

    final fixedListContent = fixedList.isEmpty
        ? '''
        <div class="welcome-card" style="margin-top: 16px;">
          <div class="welcome-card-icon">🍃</div>
          <h3>No Fixed Semantics Found</h3>
          <p>No verified interactive widgets with semantics identifiers detected on this branch yet.</p>
        </div>
        '''
        : '''
        <div class="table-container" style="background: var(--bg-secondary); border: 1px solid var(--border-color); border-radius: 12px; overflow: hidden; margin-top: 16px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);">
          <table style="width: 100%; border-collapse: collapse; text-align: left;">
            <thead>
              <tr style="background: #F8FAFC; border-bottom: 1px solid var(--border-color);">
                <th style="padding: 12px 16px; font-size: 0.75em; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px;">Line</th>
                <th style="padding: 12px 16px; font-size: 0.75em; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px;">Widget</th>
                <th style="padding: 12px 16px; font-size: 0.75em; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px;">Semantics ID</th>
                <th style="padding: 12px 16px; font-size: 0.75em; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px;">File Path</th>
              </tr>
            </thead>
            <tbody>
              $fixedRowsHtml
            </tbody>
          </table>
        </div>
        ''';

    final htmlContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Semantics Audit Report</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-primary: #F8FAFC;
      --bg-secondary: #FFFFFF;
      --text-main: #0F172A;
      --text-muted: #64748B;
      --border-color: #E2E8F0;
      
      --brand-primary: #3B82F6;
      --brand-primary-hover: #2563EB;
      --brand-primary-light: #EFF6FF;
      
      --success: #10B981;
      --success-light: #ECFDF5;
      
      --danger: #EF4444;
      --danger-light: #FEF2F2;
      
      --sidebar-width: 320px;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
      background: var(--bg-primary);
      color: var(--text-main);
      height: 100vh;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }

    /* Top Navigation Header */
    header {
      background: var(--bg-secondary);
      border-bottom: 1px solid var(--border-color);
      padding: 16px 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      z-index: 10;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
      flex-shrink: 0;
    }

    .header-logo {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .brand-mark {
      width: 36px;
      height: 36px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .brand-mark svg {
      width: 36px;
      height: 36px;
      display: block;
      filter: drop-shadow(0 6px 12px rgba(37, 99, 235, 0.18));
    }

    .header-title h1 {
      font-size: 1.25em;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: #1E3A8A;
    }

    .header-status {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .status-pill {
      background: $statusColor;
      color: white;
      padding: 6px 16px;
      border-radius: 99px;
      font-weight: 700;
      font-size: 0.8em;
      letter-spacing: 0.5px;
    }

    /* Main Container (Split view) */
    .main-layout {
      display: flex;
      flex: 1;
      overflow: hidden;
      position: relative;
    }

    /* Sidebar Styles */
    .sidebar {
      width: var(--sidebar-width);
      background: var(--bg-secondary);
      border-right: 1px solid var(--border-color);
      display: flex;
      flex-direction: column;
      flex-shrink: 0;
      transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .sidebar-search-box {
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
    }

    .search-input-wrapper {
      position: relative;
    }

    .search-input-wrapper svg {
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-muted);
    }

    .search-input {
      width: 100%;
      padding: 10px 12px 10px 36px;
      border: 1px solid var(--border-color);
      border-radius: 8px;
      font-family: inherit;
      font-size: 0.9em;
      background: var(--bg-primary);
      outline: none;
      transition: border-color 0.2s, box-shadow 0.2s;
    }

    .search-input:focus {
      border-color: var(--brand-primary);
      box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
      background: var(--bg-secondary);
    }

    .sidebar-list {
      flex: 1;
      overflow-y: auto;
      padding: 12px 8px;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .sidebar-section-title {
      padding: 8px 16px;
      font-size: 0.75em;
      font-weight: 700;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .sidebar-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s;
      user-select: none;
    }

    .sidebar-item:hover {
      background: var(--bg-primary);
    }

    .sidebar-item.active {
      background: var(--brand-primary-light);
      color: var(--brand-primary-hover);
    }

    .sidebar-item-info {
      display: flex;
      flex-direction: column;
      gap: 2px;
      overflow: hidden;
      flex: 1;
      margin-right: 8px;
    }

    .file-name {
      font-weight: 600;
      font-size: 0.9em;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .file-dir {
      font-size: 0.7em;
      color: var(--text-muted);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .sidebar-item.active .file-dir {
      color: var(--brand-primary);
    }

    .badge-count {
      background: var(--danger-light);
      color: var(--danger);
      padding: 2px 8px;
      border-radius: 99px;
      font-size: 0.75em;
      font-weight: 700;
      flex-shrink: 0;
    }

    .sidebar-item.active .badge-count {
      background: var(--brand-primary);
      color: white;
    }

    /* Content Area Styles */
    .content-area {
      flex: 1;
      overflow-y: auto;
      background: var(--bg-primary);
      display: flex;
      flex-direction: column;
      position: relative;
    }

    /* Overview Dashboard Panel */
    .dashboard-panel {
      padding: 40px;
      max-width: 900px;
      margin: 0 auto;
      width: 100%;
      animation: fadeIn 0.4s ease-out;
    }

    .dashboard-header {
      margin-bottom: 32px;
    }

    .dashboard-header h2 {
      font-size: 2.2em;
      font-weight: 800;
      letter-spacing: -1px;
      margin-bottom: 8px;
    }

    .dashboard-header p {
      color: var(--text-muted);
      font-size: 1.1em;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 24px;
      margin-bottom: 40px;
    }

    .stat-card {
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      padding: 24px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .stat-card-title {
      font-size: 0.8em;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-muted);
    }

    .stat-card-value {
      font-size: 2.5em;
      font-weight: 800;
      line-height: 1;
    }

    .stat-card.danger .stat-card-value {
      color: var(--danger);
    }

    .stat-card.success .stat-card-value {
      color: var(--success);
    }

    .welcome-card {
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      padding: 32px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);
      text-align: center;
    }

    .welcome-card-icon {
      font-size: 3em;
      margin-bottom: 16px;
    }

    .welcome-card h3 {
      font-size: 1.25em;
      margin-bottom: 8px;
    }

    .welcome-card p {
      color: var(--text-muted);
      max-width: 500px;
      margin: 0 auto;
      font-size: 0.95em;
      line-height: 1.6;
    }

    /* File Panel Styles */
    .file-panel {
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 20px;
      animation: slideIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .panel-header {
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      padding: 20px 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 20px;
      flex-wrap: wrap;
    }

    .panel-title-wrapper {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .panel-file-icon {
      font-size: 2em;
    }

    .panel-file-title {
      font-size: 1.25em;
      font-weight: 700;
    }

    .panel-file-path {
      font-size: 0.85em;
      color: var(--text-muted);
      word-break: break-all;
    }

    .panel-actions {
      display: flex;
      gap: 8px;
    }

    .btn {
      background: var(--bg-secondary);
      border: 1px solid #CBD5E1;
      color: #475569;
      padding: 8px 16px;
      border-radius: 8px;
      font-size: 0.85em;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
      outline: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }

    .btn:hover {
      background: var(--bg-primary);
      border-color: #94A3B8;
      color: var(--text-main);
    }

    .btn-primary {
      background: var(--brand-primary);
      color: white;
      border-color: var(--brand-primary);
    }

    .btn-primary:hover {
      background: var(--brand-primary-hover);
      color: white;
      border-color: var(--brand-primary-hover);
    }

    /* Accordion Issue Cards */
    .issues-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .issue-card {
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      overflow: hidden;
      transition: box-shadow 0.2s, border-color 0.2s;
    }

    .issue-card.error {
      border-left: 4px solid #EF4444;
    }

    .issue-card.warning {
      border-left: 4px solid #F59E0B;
    }

    .issue-card.expanded {
      border-color: #CBD5E1;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.03);
    }

    .issue-header {
      padding: 16px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      cursor: pointer;
      user-select: none;
      gap: 16px;
    }

    .issue-header:hover {
      background: #FAFAFA;
    }

    .line-badge {
      background: #F1F5F9;
      color: #475569;
      font-weight: 700;
      font-size: 0.8em;
      padding: 4px 10px;
      border-radius: 6px;
      font-family: 'JetBrains Mono', monospace;
    }

    .widget-badge {
      background: var(--brand-primary-light);
      color: var(--brand-primary-hover);
      border: 1px solid #DBEAFE;
      font-weight: 700;
      font-size: 0.8em;
      padding: 3px 10px;
      border-radius: 6px;
    }

    .suggestion-wrapper {
      display: flex;
      align-items: center;
      gap: 6px;
      background: var(--success-light);
      border: 1px solid #D1FAE5;
      padding: 3px 10px;
      border-radius: 6px;
      font-size: 0.8em;
    }

    .suggestion-prefix {
      color: var(--text-muted);
      font-weight: 600;
    }

    .suggestion-val {
      color: var(--success);
      font-weight: 700;
      font-family: 'JetBrains Mono', monospace;
    }

    .btn-copy {
      background: none;
      border: none;
      color: var(--brand-primary);
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 4px;
      font-size: 0.8em;
      font-weight: 600;
      padding: 6px 10px;
      border-radius: 6px;
      transition: background-color 0.2s;
    }

    .btn-copy:hover {
      background: var(--brand-primary-light);
    }

    .btn-copy.copied {
      color: var(--success);
      background: var(--success-light);
    }

    .caret-icon {
      color: var(--text-muted);
      transition: transform 0.25s ease;
      display: flex;
      align-items: center;
    }

    .issue-card.expanded .caret-icon {
      transform: rotate(180deg);
    }

    .issue-body {
      display: none;
      padding: 0 20px 20px 20px;
      border-top: 1px solid var(--border-color);
      background: #FCFCFD;
    }

    .issue-card.expanded .issue-body {
      display: block;
    }

    /* Code Container Styles */
    .code-container {
      margin-top: 16px;
      border-radius: 8px;
      overflow: hidden;
      border: 1px solid var(--border-color);
    }

    .code-header {
      background: #F1F5F9;
      padding: 8px 16px;
      font-size: 0.75em;
      color: var(--text-muted);
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .code-box {
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.85em;
      background: #0F172A;
      color: #E2E8F0;
      padding: 16px;
      max-height: 200px;
      overflow-y: auto;
      line-height: 1.5;
      white-space: pre-wrap;
      word-break: break-all;
    }

    /* Utility animations */
    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    @keyframes slideIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* Responsive Sidebar Toggle / Floating Drawer UX */
    .sidebar-toggle-btn {
      display: none;
      background: none;
      border: none;
      cursor: pointer;
      color: var(--text-main);
      padding: 8px;
      border-radius: 8px;
    }

    .sidebar-toggle-btn:hover {
      background: var(--bg-primary);
    }

    @media (max-width: 768px) {
      .sidebar-toggle-btn {
        display: block;
      }

      .sidebar {
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        z-index: 50;
        transform: translateX(-100%);
        box-shadow: 10px 0 30px rgba(0, 0, 0, 0.1);
      }

      .sidebar.open {
        transform: translateX(0);
      }

      .sidebar-backdrop {
        display: none;
        position: absolute;
        inset: 0;
        background: rgba(15, 23, 42, 0.4);
        z-index: 40;
        backdrop-filter: blur(2px);
      }

      .sidebar-backdrop.show {
        display: block;
      }
    }
  </style>
</head>
<body>

  <!-- Top Header Navigation -->
  <header>
    <div class="header-logo">
      <button class="sidebar-toggle-btn" onclick="toggleSidebar()">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
      </button>
      <div class="brand-mark">$brandLogoSvg</div>
      <div class="header-title">
        <h1>${BrandIdentity.appName}</h1>
      </div>
    </div>
    <div class="header-status">
      <span class="status-pill">$statusText</span>
    </div>
  </header>

  <div class="main-layout">
    <!-- Mobile Sidebar Backdrop -->
    <div class="sidebar-backdrop" id="backdrop" onclick="toggleSidebar(false)"></div>

    <!-- Left Sidebar: Search & File Tree List -->
    <aside class="sidebar" id="sidebar">
      <div class="sidebar-search-box">
        <div class="search-input-wrapper">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
          <input type="text" class="search-input" id="search" placeholder="Search files..." oninput="filterFiles()">
        </div>
      </div>
      <div class="sidebar-list">
        <div class="sidebar-section-title">Views</div>
        <div class="sidebar-item active" id="nav-overview" onclick="showOverview()">
          <div class="sidebar-item-info">
            <span class="file-name">Dashboard Overview</span>
          </div>
        </div>
        <div class="sidebar-item" id="nav-fixed" onclick="showFixed()">
          <div class="sidebar-item-info">
            <span class="file-name">Fixed Semantics</span>
          </div>
          <span class="badge-count" style="background: var(--success-light); color: var(--success);">${fixedList.length}</span>
        </div>
        
        <!-- Sidebar Sections -->
        <div class="sidebar-section-title" id="errors-section-title" style="border-top: 1px solid var(--border-color); margin-top: 8px; padding-top: 12px; color: var(--danger); display: flex; align-items: center; gap: 6px;">
          <span>❌</span> Files with Errors (${grouped.values.where((list) => list.any((i) => !i.isWarning)).length})
        </div>
        <div id="sidebar-errors-list">
          $sidebarErrorsHtml
        </div>

        <div class="sidebar-section-title" id="warnings-section-title" style="border-top: 1px solid var(--border-color); margin-top: 8px; padding-top: 12px; color: #D97706; display: flex; align-items: center; gap: 6px;">
          <span>⚠️</span> Files with Warnings Only (${grouped.values.where((list) => list.every((i) => i.isWarning)).length})
        </div>
        <div id="sidebar-warnings-list">
          $sidebarWarningsHtml
        </div>
      </div>
    </aside>

    <!-- Right Content Area -->
    <main class="content-area">
      <!-- Default Overview Dashboard Panel -->
      <div class="dashboard-panel" id="overview-panel">
        <div class="dashboard-header">
          <h2>Audit Overview</h2>
          <p>Semantics Identifier validation summary for the current audit session.</p>
        </div>
        
        <div class="stats-grid">
          <div class="stat-card danger">
            <span class="stat-card-title">Remaining Errors</span>
            <span class="stat-card-value">${errors.length}</span>
          </div>
          <div class="stat-card warning" style="border-color: #FDE68A; background: #FFFDF5;">
            <span class="stat-card-title" style="color: #B45309;">Warnings</span>
            <span class="stat-card-value" style="color: #D97706;">${warnings.length}</span>
          </div>
          <div class="stat-card">
            <span class="stat-card-title">Affected Files</span>
            <span class="stat-card-value">${grouped.length}</span>
          </div>
          <div class="stat-card success">
            <span class="stat-card-title">Fixed in Branch</span>
            <span class="stat-card-value">${fixedList.length}</span>
          </div>
        </div>

        <div class="welcome-card">
          ${issues.isEmpty ? '''
            <div class="welcome-card-icon">🎉</div>
            <h3>Excellent! Code Base Compliant</h3>
            <p>All scanned changed widgets have valid semantics identifiers configured. High automation capability achieved.</p>
          ''' : '''
            <div class="welcome-card-icon">🔍</div>
            <h3>Select a File from Sidebar</h3>
            <p>Choose any file on the left navigation to inspect its remaining missing semantics issues, see suggested IDs, and copy code snippets.</p>
          '''}
        </div>
      </div>

      <!-- Verified Fixed Semantics Panel -->
      <div class="file-panel" id="panel-fixed" style="display: none;">
        <div class="panel-header" style="border-left: 4px solid var(--success);">
          <div class="panel-title-wrapper">
            <span class="panel-file-icon">✅</span>
            <div>
              <h2 class="panel-file-title" style="color: var(--success);">Fixed Semantics</h2>
              <span class="panel-file-path">Verified widgets with semantics identifiers configured in this branch</span>
            </div>
          </div>
        </div>
        $fixedListContent
      </div>

      <!-- Individual File Panels -->
      $filePanelsHtml
    </main>
  </div>

  <script>
    let activeFileId = null;
    let isOverviewActive = true;
    let isFixedActive = false;

    function resetActiveNav() {
      if (activeFileId) {
        const prevPanel = document.getElementById('panel-' + activeFileId);
        if (prevPanel) prevPanel.style.display = 'none';
        
        const prevNav = document.getElementById('nav-' + activeFileId);
        if (prevNav) prevNav.classList.remove('active');
        activeFileId = null;
      }
      
      if (isOverviewActive) {
        document.getElementById('overview-panel').style.display = 'none';
        document.getElementById('nav-overview').classList.remove('active');
        isOverviewActive = false;
      }
      
      if (isFixedActive) {
        document.getElementById('panel-fixed').style.display = 'none';
        document.getElementById('nav-fixed').classList.remove('active');
        isFixedActive = false;
      }
    }

    function showOverview() {
      toggleSidebar(false);
      resetActiveNav();
      document.getElementById('overview-panel').style.display = 'block';
      document.getElementById('nav-overview').classList.add('active');
      isOverviewActive = true;
    }

    function showFixed() {
      toggleSidebar(false);
      resetActiveNav();
      document.getElementById('panel-fixed').style.display = 'flex';
      document.getElementById('nav-fixed').classList.add('active');
      isFixedActive = true;
    }

    function showFile(fileId) {
      toggleSidebar(false);
      resetActiveNav();

      const nextPanel = document.getElementById('panel-' + fileId);
      if (nextPanel) nextPanel.style.display = 'flex';

      const nextNav = document.getElementById('nav-' + fileId);
      if (nextNav) nextNav.classList.add('active');

      activeFileId = fileId;
    }

    function toggleIssue(headerEl) {
      const card = headerEl.parentElement;
      card.classList.toggle('expanded');
    }

    function toggleAllAccordions(fileId, expand) {
      const panel = document.getElementById('panel-' + fileId);
      if (panel) {
        const cards = panel.querySelectorAll('.issue-card');
        cards.forEach(card => {
          if (expand) {
            card.classList.add('expanded');
          } else {
            card.classList.remove('expanded');
          }
        });
      }
    }

    function filterFiles() {
      const query = document.getElementById('search').value.toLowerCase();
      const items = document.querySelectorAll('.sidebar-item[data-filepath]');
      items.forEach(item => {
        const filepath = item.getAttribute('data-filepath');
        if (filepath.includes(query)) {
          item.style.display = 'flex';
        } else {
          item.style.display = 'none';
        }
      });
    }

    function toggleSidebar(show) {
      const sidebar = document.getElementById('sidebar');
      const backdrop = document.getElementById('backdrop');
      
      if (show === undefined) {
        sidebar.classList.toggle('open');
        backdrop.classList.toggle('show');
      } else if (show) {
        sidebar.classList.add('open');
        backdrop.classList.add('show');
      } else {
        sidebar.classList.remove('open');
        backdrop.classList.remove('show');
      }
    }

    function copyId(event, text) {
      event.stopPropagation(); // Avoid triggering accordion toggle
      navigator.clipboard.writeText(text).then(() => {
        const btn = event.currentTarget;
        const originalHtml = btn.innerHTML;
        btn.innerHTML = `
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
          Copied!
        `;
        btn.classList.add('copied');
        setTimeout(() => {
          btn.innerHTML = originalHtml;
          btn.classList.remove('copied');
        }, 2000);
      });
    }
  </script>
</body>
</html>
''';

    await File('$dirPath/report.html').writeAsString(htmlContent);
    print('\x1B[1;32m✓ HTML report created: $dirPath/report.html\x1B[0m');
  }
}
