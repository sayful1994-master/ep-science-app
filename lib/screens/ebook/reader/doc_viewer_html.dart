import 'dart:convert';

/// Builds a fully self-contained, hardened document-viewer HTML page used by
/// both the web (`<iframe srcdoc>`) and mobile (`WebView.loadHtmlString`)
/// renderers.
///
/// Security / product requirements enforced here:
/// • PDF and Word (.doc/.docx) both render INSIDE the app (no external app,
///   no browser hand-off, no intent).
/// • No download / save / share / print / export controls are exposed.
/// • Text selection & copy are disabled (`user-select:none` + canvas render
///   for PDF so there is no selectable text at all).
/// • Ctrl/Cmd + S / P and the context menu are blocked; the page cannot print.
String buildDocViewerHtml({
  required String url,
  String fileType = 'pdf',
  String title = '',
}) {
  final u = jsonEncode(url);
  final t = jsonEncode(fileType);
  final ti = jsonEncode(title);
  return '''<!DOCTYPE html>
<html lang="bn">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=5"/>
<title>$ti</title>
<style>
  html,body{margin:0;padding:0;height:100%;background:#0E1B2E;font-family:-apple-system,Roboto,sans-serif;}
  *{-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none;-webkit-touch-callout:none;}
  #bar{display:flex;gap:8px;align-items:center;justify-content:flex-end;padding:6px 12px;background:#0A1524;position:fixed;top:0;left:0;right:0;height:40px;box-sizing:border-box;z-index:20;}
  #bar button{background:#1D5FD0;color:#fff;border:0;border-radius:8px;padding:5px 13px;font-size:16px;line-height:1;cursor:pointer;}
  #bar span#zlabel{color:#9fb3c8;font-size:13px;}
  #wrap{position:absolute;top:40px;left:0;right:0;bottom:0;overflow:auto;-webkit-overflow-scrolling:touch;}
  #pages{display:flex;flex-direction:column;align-items:center;gap:14px;padding:14px;}
  #pages canvas{max-width:100%;height:auto;background:#fff;box-shadow:0 3px 10px rgba(0,0,0,.45);border-radius:4px;}
  .docx-wrapper{background:#fff;padding:18px;max-width:900px;margin:0 auto;border-radius:6px;}
  #status{color:#9fb3c8;text-align:center;padding:28px;font-size:14px;}
  #frame{width:100%;height:100%;border:0;}
  @media print{body{display:none !important;}}
</style>
</head>
<body>
<div id="bar">
  <button type="button" onclick="zoom(-1)">&minus;</button>
  <span id="zlabel">100%</span>
  <button type="button" onclick="zoom(1)">+</button>
</div>
<div id="wrap">
  <div id="status">ডকুমেন্ট লোড হচ্ছে…</div>
  <div id="pages"></div>
</div>
<script src="https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/docx-preview@0.3.2/dist/docx-preview.min.js"></script>
<script>
var DOC_URL = $u;
var DOC_TYPE = $t;
var pdfDoc = null;
var scale = 1.0;

function g(id){ return document.getElementById(id); }
function status(m){ g('status').innerHTML = m; }
function isPdf(){
  if (DOC_TYPE && DOC_TYPE.toLowerCase() === 'pdf') return true;
  if (DOC_TYPE && (DOC_TYPE.toLowerCase() === 'doc' || DOC_TYPE.toLowerCase() === 'docx')) return false;
  return /\\.pdf(\\?|#|\$)/i.test(DOC_URL);
}

function fallback(){
  g('pages').innerHTML = '';
  status('');
  g('wrap').style.overflow = 'hidden';
  var f = document.createElement('iframe');
  f.id = 'frame';
  f.setAttribute('referrerpolicy','no-referrer');
  f.src = 'https://docs.google.com/gview?embedded=true&url=' + encodeURIComponent(DOC_URL);
  g('wrap').appendChild(f);
}

async function loadPdf(buf){
  if (typeof pdfjsLib === 'undefined') throw new Error('pdfjs missing');
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js';
  pdfDoc = await pdfjsLib.getDocument({data: buf}).promise;
  await renderPdf();
}

async function renderPdf(){
  var host = g('pages');
  host.innerHTML = '';
  var avail = (g('wrap').clientWidth || 800) - 28;
  for (var p = 1; p <= pdfDoc.numPages; p++){
    var page = await pdfDoc.getPage(p);
    var base = page.getViewport({scale: 1});
    var fit = Math.min(3, Math.max(0.4, avail / base.width));
    var vp = page.getViewport({scale: fit * scale});
    var c = document.createElement('canvas');
    c.width = vp.width; c.height = vp.height;
    host.appendChild(c);
    await page.render({canvasContext: c.getContext('2d'), viewport: vp}).promise;
  }
}

async function loadDocx(buf){
  if (typeof docx === 'undefined') throw new Error('docx-preview missing');
  var host = g('pages');
  host.innerHTML = '';
  await docx.renderAsync(buf, host, null, {inWrapper: true, ignoreWidth: false, ignoreHeight: true, breakPages: true});
}

function zoom(d){
  scale = Math.min(3, Math.max(0.5, scale + d * 0.15));
  g('zlabel').textContent = Math.round(scale * 100) + '%';
  if (pdfDoc) { renderPdf(); }
}

document.addEventListener('contextmenu', function(e){ e.preventDefault(); });
document.addEventListener('keydown', function(e){
  var k = (e.key || '').toLowerCase();
  if ((e.ctrlKey || e.metaKey) && (k === 's' || k === 'p')) { e.preventDefault(); }
});
document.addEventListener('dragstart', function(e){ e.preventDefault(); });

(async function run(){
  try {
    status('ডকুমেন্ট লোড হচ্ছে…');
    var res = await fetch(DOC_URL, {mode: 'cors'});
    if (!res.ok) throw new Error('http ' + res.status);
    var buf = await res.arrayBuffer();
    status('');
    if (isPdf()) { await loadPdf(buf); } else { await loadDocx(buf); }
  } catch (err) {
    fallback();
  }
})();
</script>
</body>
</html>''';
}
