;;; ox-telegram.el --- Telegram MarkdownV2 Back-End for Org Export Engine -*- lexical-binding: t; -*-

;; Copyright (C) 2014-2017 Lars Tveito
;; Copyright (C) 2024 Modified for Telegram MarkdownV2

;; Author: Based on ox-gfm by Lars Tveito
;; Keywords: org, wp, markdown, telegram

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library implements a Markdown back-end (Telegram MarkdownV2) for Org
;; exporter, based on the `md' back-end.

;; Telegram MarkdownV2 features:
;; - *bold text*
;; - _italic text_
;; - __underline__
;; - ~strikethrough~
;; - ||spoiler||
;; - `inline fixed-width code`
;; - ```pre-formatted fixed-width code block```
;; - [inline URL](http://www.example.com/)
;; - Special characters must be escaped: _ * [ ] ( ) ~ ` > # + - = | { } . !

;;; Code:

(require 'ox-md)
(require 'ox-publish)

;;; User-Configurable Variables

(defgroup org-export-telegram nil
  "Options specific to Telegram MarkdownV2 export back-end."
  :tag "Org Telegram MarkdownV2"
  :group 'org-export
  :version "24.4"
  :package-version '(Org . "8.0"))

(defcustom org-telegram-escape-special-chars t
  "Whether to escape special characters for Telegram MarkdownV2.
When non-nil, escape characters: _ * [ ] ( ) ~ ` > # + - = | { } . !"
  :type 'boolean
  :group 'org-export-telegram)

;;; Define Back-End

(org-export-define-derived-backend 'telegram 'md
  :menu-entry
  '(?t "Export to Telegram MarkdownV2"
       ((?T "To temporary buffer"
            (lambda (a s v b) (org-telegram-export-as-markdown a s v)))
        (?t "To file" (lambda (a s v b) (org-telegram-export-to-markdown a s v)))
        (?o "To file and open"
            (lambda (a s v b)
              (if a (org-telegram-export-to-markdown t s v)
                (org-open-file (org-telegram-export-to-markdown nil s v)))))))
  :translate-alist '((inner-template . org-telegram-inner-template)
                     (paragraph . org-telegram-paragraph)
                     (bold . org-telegram-bold)
                     (italic . org-telegram-italic)
                     (underline . org-telegram-underline)
                     (strike-through . org-telegram-strike-through)
                     (code . org-telegram-code)
                     (verbatim . org-telegram-verbatim)
                     (src-block . org-telegram-src-block)
                     (example-block . org-telegram-example-block)
                     (table . org-telegram-table)
                     (table-row . org-telegram-table-row)
                     (table-cell . org-telegram-table-cell)
                     (link . org-telegram-link)
                     (headline . org-telegram-headline)))

;;; Helper Functions

(defun org-telegram-unescape-html-entities (text)
  "Convert HTML entities in TEXT to regular characters.
For example, &ldquo; -> \" and &rdquo; -> \"."
  (if (not text)
      ""
    (let ((result text))
      ;; Common HTML entities
      (setq result (replace-regexp-in-string "&ldquo;" "\"" result))
      (setq result (replace-regexp-in-string "&rdquo;" "\"" result))
      (setq result (replace-regexp-in-string "&lsquo;" "'" result))
      (setq result (replace-regexp-in-string "&rsquo;" "'" result))
      (setq result (replace-regexp-in-string "&quot;" "\"" result))
      (setq result (replace-regexp-in-string "&amp;" "&" result))
      (setq result (replace-regexp-in-string "&lt;" "<" result))
      (setq result (replace-regexp-in-string "&gt;" ">" result))
      result)))

(defun org-telegram-escape (text)
  "Escape special characters for Telegram MarkdownV2.
Escape characters: _ * [ ] ( ) ~ ` > # + - = | { } . !
If TEXT is nil, return empty string."
  (if (not text)
      ""
    (let ((unescaped-text (org-telegram-unescape-html-entities text)))
      (if org-telegram-escape-special-chars
          (replace-regexp-in-string
           "\\([_*\\[\\]()~`>#+=|{}.!]\\)" "\\\\\\1" unescaped-text)
        unescaped-text))))

(defun org-telegram-plain-text (text)
  "Convert TEXT to plain text without any Markdown formatting."
  (org-telegram-escape text))

;;; Transcode Functions

;;;; Paragraph

(defun org-telegram-paragraph (paragraph contents info)
  "Transcode PARAGRAPH element into Telegram MarkdownV2 format.
CONTENTS is the paragraph contents.  INFO is a plist used as a
communication channel."
  (let ((contents (org-trim contents)))
    (when (and contents (not (string-empty-p contents)))
      (concat (org-telegram-plain-text contents) "\n\n"))))

;;;; Bold

(defun org-telegram-bold (bold contents info)
  "Transcode BOLD element into Telegram MarkdownV2 format.
CONTENTS is the bold text.  INFO is a plist used as a
communication channel."
  (format "**%s**" (org-telegram-escape contents)))

;;;; Italic

(defun org-telegram-italic (italic contents info)
  "Transcode ITALIC element into Telegram MarkdownV2 format.
CONTENTS is the italic text.  INFO is a plist used as a
communication channel."
  (format "__%s__" (org-telegram-escape contents)))

;;;; Underline

(defun org-telegram-underline (underline contents info)
  "Transcode UNDERLINE element into Telegram MarkdownV2 format.
CONTENTS is the underlined text.  INFO is a plist used as a
communication channel."
  (format "__%s__" (org-telegram-escape contents)))

;;;; Strike-Through

(defun org-telegram-strike-through (_strike-through contents _info)
  "Transcode STRIKE-THROUGH element into Telegram MarkdownV2 format.
CONTENTS is the text with strike-through markup.  INFO is a plist
holding contextual information."
  (format "~~%s~~" (org-telegram-escape contents)))

;;;; Code

(defun org-telegram-code (code _contents info)
  "Transcode CODE element into Telegram MarkdownV2 format.
_CONTENTS is ignored.  INFO is a plist used as a communication channel."
  (let ((text (org-element-property :value code)))
    (format "`%s`" (org-telegram-escape text))))

;;;; Verbatim

(defun org-telegram-verbatim (verbatim _contents info)
  "Transcode VERBATIM element into Telegram MarkdownV2 format.
_CONTENTS is ignored.  INFO is a plist used as a communication channel."
  (let ((text (org-element-property :value verbatim)))
    (format "`%s`" (org-telegram-escape text))))

;;;; Src Block

(defun org-telegram-src-block (src-block _contents info)
  "Transcode SRC-BLOCK element into Telegram MarkdownV2 format.
_CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (let ((code (org-export-format-code-default src-block info)))
    (concat "```" (org-telegram-escape code) "```")))

;;;; Example Block

(defalias 'org-telegram-example-block #'org-telegram-src-block)

;;;; Link

(defun org-telegram-link (link desc info)
  "Transcode LINK element into Telegram MarkdownV2 format.
DESC is the link description.  INFO is a plist used as a
communication channel."
  (let* ((type (org-element-property :type link))
         (raw-path (org-element-property :path link))
         ;; For http/https links, use the raw path directly
         ;; For other link types, use org-export-resolve-link
         (full-path (cond
                     ((member type '("http" "https" "ftp" "mailto"))
                      (concat type ":" raw-path))
                     ((string= type "file")
                      ;; For file links, try to resolve them
                      (let ((resolved (org-export-resolve-link link info)))
                        (if (stringp resolved) resolved raw-path)))
                     (t
                      ;; For other link types, try to resolve them
                      (let ((resolved (org-export-resolve-link link info)))
                        (if (stringp resolved) resolved raw-path)))))
         ;; Get the description
         (desc-text (org-export-data desc info)))
    ;; Check different cases:
    (cond
     ;; Case 1: No description (empty or nil)
     ((or (not desc-text) (string-empty-p desc-text))
      ;; Just output the URL without Markdown link syntax
      full-path)
     ;; Case 2: Description is the same as the link
     ((string= desc-text full-path)
      ;; Just output the URL without Markdown link syntax
      full-path)
     ;; Case 3: Different description
     (t
      ;; Format as a proper Markdown link
      (let ((escaped-text (org-telegram-escape desc-text)))
        (format "[%s](%s)" escaped-text full-path))))))

;;;; Headline

(defun org-telegram-headline (headline contents info)
  "Transcode HEADLINE element into Telegram MarkdownV2 format.
CONTENTS is the headline contents.  INFO is a plist used as a
communication channel."
  (let* ((level (org-element-property :level headline))
         (title (org-export-data (org-element-property :title headline) info))
         (escaped-title (org-telegram-escape title))
         (bold-title (format "**%s**" escaped-title))
         ;; Create hash marks based on level (max 6 levels as per Markdown)
         (hashes (make-string (min level 6) ?#))
         ;; Add a space after the hash marks
         (heading (concat hashes " " bold-title)))
    (concat heading "\n\n" contents)))

;;;; Table-Cell

(defun org-telegram-table-cell (table-cell contents info)
  "Transcode TABLE-CELL element into Telegram MarkdownV2 format.
CONTENTS is content of the cell.  INFO is a plist used as a
communication channel."
  (or contents ""))

;;;; Table-Row

(defun org-telegram-table-row (table-row contents info)
  "Transcode TABLE-ROW element into Telegram MarkdownV2 format.
CONTENTS is cell contents of TABLE-ROW.  INFO is a plist used as a
communication channel."
  (or contents ""))

;;;; Table

(defun org-telegram-table (table contents info)
  "Transcode TABLE element into Telegram MarkdownV2 format.
CONTENTS is the contents of the table.  INFO is a plist holding
contextual information."
  ;; Always export table as a code block with raw Org-mode markup
  (let ((table-begin (org-element-property :begin table))
        (table-end (org-element-property :end table)))
    (when (and table-begin table-end)
      (let ((table-text (buffer-substring-no-properties table-begin table-end)))
        (concat "```\n" (string-trim table-text) "\n```\n\n")))))

;;;; Template

(defun org-telegram-inner-template (contents info)
  "Return body of document after converting it to Telegram MarkdownV2 syntax.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (org-trim contents))

;;; Interactive function

;;;###autoload
(defun org-telegram-export-as-markdown (&optional async subtreep visible-only)
  "Export current buffer to a Telegram MarkdownV2 buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Export is done in a buffer named "*Org Telegram Export*", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (org-export-to-buffer 'telegram "*Org Telegram Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-telegram-convert-region-to-md ()
  "Convert the region to Telegram MarkdownV2.
This can be used in any buffer, this function assume that the
current region has org-mode syntax.  For example, you can write
an itemized list in org-mode syntax in a Markdown buffer and use
this command to convert it."
  (interactive)
  (org-export-replace-region-by 'telegram))

;;;###autoload
(defun org-telegram-export-to-markdown (&optional async subtreep visible-only)
  "Export current buffer to a Telegram MarkdownV2 file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".md" subtreep)))
    (org-export-to-file 'telegram outfile async subtreep visible-only)))

;;;###autoload
(defun org-telegram-publish-to-telegram (plist filename pub-dir)
  "Publish an org file to Telegram MarkdownV2.
FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.
Return output file name."
  (org-publish-org-to 'telegram filename ".md" plist pub-dir))

(provide 'ox-telegram)

;;; ox-telegram.el ends here
