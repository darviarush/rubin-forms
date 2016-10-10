package R::Http::Mime;
# mime типы для файлов и писем

sub new { return {
    "html" => "text/html",
	"htm" => "text/html",
	"shtml" => "text/html",
    "css" => "text/css",
    "xml" => "text/xml",
    "gif" => "image/gif",
    "jpeg" => "image/jpeg",
    "jpg" => "image/jpeg",
    "jpe" => "image/jpeg",
    "js" => "text/javascript", #"application/javascript",
    "atom" => "application/atom+xml",
    "rss" => "application/rss+xml",

    "mml" => "text/mathml",
    "txt" => "text/plain",
    "jad" => "text/vnd.sun.j2me.app-descriptor",
    "wml" => "text/vnd.wap.wml",
    "htc" => "text/x-component",

    "png" => "image/png",
    "tif" => "image/tiff",
	"tiff" => "image/tiff",
    "wbmp" => "image/vnd.wap.wbmp",
    "ico" => "image/x-icon",
    "jng" => "image/x-jng",
    "bmp" => "image/x-ms-bmp",
    "svgz" => "image/svg+xml",
	"svg" => "image/svg+xml",
    "webp" => "image/webp",

    "woff" => "application/font-woff",
    "jar" => "application/java-archive",
	"war" => "application/java-archive",
	"ear" => "application/java-archive",
    "hqx" => "application/mac-binhex40",
    "doc" => "application/msword",
    "pdf" => "application/pdf",
    "ps" => "application/postscript",
	"ai" => "application/postscript",
	"eps" => "application/postscript",
    "rtf" => "application/rtf",
    "xls" => "application/vnd.ms-excel",
    "eot" => "application/vnd.ms-fontobject",
    "ppt" => "application/vnd.ms-powerpoint",
    "wmlc" => "application/vnd.wap.wmlc",
    "kml" => "application/vnd.google-earth.kml+xml",
    "kmz" => "application/vnd.google-earth.kmz",
    "7z" => "application/x-7z-compressed",
    "cco" => "application/x-cocoa",
    "jardiff" => "application/x-java-archive-diff",
    "jnlp" => "application/x-java-jnlp-file",
    "run" => "application/x-makeself",
    "pl" => "application/x-perl",
	"pm" => "application/x-perl",
    "prc" => "application/x-pilot",
	"pdb" => "application/x-pilot",
    "rar" => "application/x-rar-compressed",
    "rpm" => "application/x-redhat-package-manager",
    "sea" => "application/x-sea",
    "swf" => "application/x-shockwave-flash",
    "sit" => "application/x-stuffit",
    "tk" => "application/x-tcl",
	"tcl" => "application/x-tcl",
    "der" => "application/x-x509-ca-cert",
	"pem" => "application/x-x509-ca-cert",
	"crt" => "application/x-x509-ca-cert",
    "xpi" => "application/x-xpinstall",
    "xhtml" => "application/xhtml+xml",
    "zip" => "application/zip",

    "bin" => "application/octet-stream",
	"dll" => "application/octet-stream",
	"exe" => "application/octet-stream",
    "deb" => "application/octet-stream",
    "dmg" => "application/octet-stream",
    "iso" => "application/octet-stream",
	"img" => "application/octet-stream",
    "msm" => "application/octet-stream",
	"msp" => "application/octet-stream",
	"msi" => "application/octet-stream",

    "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",

    "mid" => "audio/midi",
	"midi" => "audio/midi",
	"kar" => "audio/midi",
    "mp3" => "audio/mpeg",
    "ogg" => "audio/ogg",
    "m4a" => "audio/x-m4a",
    "ra" => "audio/x-realaudio",

    "3gpp" => "video/3gpp",
	"3gp" => "video/3gpp",
    "mp4" => "video/mp4",
    "mpg" => "video/mpeg",
    "mpeg" => "video/mpeg",
    "mpe" => "video/mpeg",
    "mov" => "video/quicktime",
    "webm" => "video/webm",
    "flv" => "video/x-flv",
    "m4v" => "video/x-m4v",
    "mng" => "video/x-mng",
    "asx" => "video/x-ms-asf",
    "asf" => "video/x-ms-asf",
    "wmv" => "video/x-ms-wmv",
    "avi" => "video/x-msvideo",
}}

1;
