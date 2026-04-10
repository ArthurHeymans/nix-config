{ ... }:
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";

      "x-scheme-handler/magnet" = "transmission-gtk.desktop";
      "application/x-bittorrent" = "transmission-gtk.desktop";

      "x-scheme-handler/sgnl" = "signal.desktop";
      "x-scheme-handler/signalcaptcha" = "signal.desktop";

      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";

      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-mpeg" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";

      "audio/mpeg" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/aac" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/webm" = "mpv.desktop";
      "audio/x-m4a" = "mpv.desktop";

      "application/pdf" = "evince.desktop";
      "application/postscript" = "evince.desktop";
      "image/vnd.djvu" = "evince.desktop";
      "image/x-djvu" = "evince.desktop";
      "application/x-dvi" = "evince.desktop";

      "inode/directory" = "nautilus.desktop";

      "application/epub+zip" = "calibre-ebook-viewer.desktop";
      "application/x-mobipocket-ebook" = "calibre-ebook-viewer.desktop";
      "application/x-cbz" = "calibre-ebook-viewer.desktop";

      "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop";
      "application/vnd.oasis.opendocument.text-template" = "libreoffice-writer.desktop";
      "application/msword" = "libreoffice-writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
        "libreoffice-writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template" =
        "libreoffice-writer.desktop";
      "application/vnd.ms-word.document.macroenabled.12" = "libreoffice-writer.desktop";

      "application/vnd.oasis.opendocument.spreadsheet" = "libreoffice-calc.desktop";
      "application/vnd.oasis.opendocument.spreadsheet-template" = "libreoffice-calc.desktop";
      "application/vnd.ms-excel" = "libreoffice-calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "libreoffice-calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = "libreoffice-calc.desktop";
      "text/csv" = "libreoffice-calc.desktop";

      "application/vnd.oasis.opendocument.presentation" = "libreoffice-impress.desktop";
      "application/vnd.oasis.opendocument.presentation-template" = "libreoffice-impress.desktop";
      "application/vnd.ms-powerpoint" = "libreoffice-impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
        "libreoffice-impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.template" =
        "libreoffice-impress.desktop";

      "application/vnd.oasis.opendocument.graphics" = "libreoffice-draw.desktop";
      "image/x-xcf" = "gimp.desktop";
    };
  };
}
