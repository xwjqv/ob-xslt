;;; ob-xslt.el --- org-babel functions for xslt evaluation

;; Copyright (C) Dr. Ian FitzPatrick

;; Author: Dr. Ian FitzPatrick
;; Keywords: literate programming, reproducible research
;; Homepage: https://orgmode.org
;; Version: 0.01
;; Package-Requires: ((emacs "25.1"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; process xml documents with xslt from org babel
;;

;;; Requirements:

;; xsltproc

;;; Code:
(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
(require 's)

;; possibly require modes required for your language
(define-derived-mode xslt-mode nxml-mode "xslt"
  "Major mode for editing xslt templates.")


(defcustom org-babel-xslt-command
  (car (seq-filter 'executable-find '("saxon" "xsltproc")))
  "Name of xslt engine"
  :group 'org-babel
  :type 'string)

;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("xslt" . "xslt"))

;; optionally declare default header arguments for this language
(defvar org-babel-default-header-args:xslt '()) ; TODO use this for input in stead of variable

;; This function expands the body of a source code block by doing
;; things like prepending argument definitions to the body, it should
;; be called by the `org-babel-execute:xslt' function below.
(defun org-babel-expand-body:xslt (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body."
                                        ;(require 'inf-xslt) : TODO check if needed
  body ; TODO translate params to xml variables
  )

;; This is the main function which is called to evaluate a code
;; block.
;;
;; This function will evaluate the body of the source code and
;; return the results as emacs-lisp depending on the value of the
;; :results header argument
;; - output means that the output to STDOUT will be captured and
;;   returned
;; - value means that the value of the last statement in the
;;   source code block will be returned
;;
;; The most common first step in this function is the expansion of the
;; PARAMS argument using `org-babel-process-params'.
;;
;; Please feel free to not implement options which aren't appropriate
;; for your language (e.g. not all languages support interactive
;; "session" evaluation).  Also you are free to define any new header
;; arguments which you feel may be useful -- all header arguments
;; specified by the user will be available in the PARAMS variable.
(defun org-babel-execute:xslt (body params)
  "Execute a block of xslt code with org-babel.
This function is called by `org-babel-execute-src-block'"
  (message "executing xslt source code block")
  (let*
      (
       ;; (xml (cdr (cdr (assoc :var params) ) ))
       (vars (org-babel--get-vars params))
       (param-items '())
       (xml (cdr (assq 'input vars)))
       (xml (s-replace-regexp "^#\+.*\n" "" xml))) ; remove orgmode markup from input
    (mapcar (lambda (var)
              (when (not (eq (car var) 'input))
                (add-to-list 'param-items (format "%s=%s" (car var) (cdr var)) t)))
            vars)
    (org-babel-eval-xslt body xml param-items)
    ;; when forming a shell command, or a fragment of code in some
    ;; other language, please preprocess any file names involved with
    ;; the function `org-babel-process-file-name'. (See the way that
    ;; function is used in the language files)
    ))

(defun org-babel-eval-xslt (body xml param-items)
  "Run CMD on BODY.
If CMD succeeds then return its results, otherwise display
STDERR with `org-babel-eval-error-notify'."
  (let (
        (xml-file (org-babel-temp-file "ob-xslt-xml-"))
        (xsl-file (org-babel-temp-file "ob-xslt-xsl-"))
        ;; (output-file (org-babel-temp-file "ob-xslt-out-"))
        cmd-params
        exit-code)
    (with-temp-file xsl-file (insert body))
    (with-temp-file xml-file (insert xml))
    (pcase org-babel-xslt-command
      ("saxon" (setq cmd-params (append param-items (list xml-file xsl-file))))
      ("xsltproc" (setq cmd-params (append param-items (list xsl-file xml-file)))))
    ;; (with-current-buffer err-buff (erase-buffer))
    ;; (setq exit-code
    ;;       (shell-command (format "%s %s %s %s"  org-babel-xslt-command param-str xml-file xsl-file) output-file err-buff))
    (with-temp-buffer
      (setq exit-code (apply #'call-process org-babel-xslt-command nil t nil (remq "" cmd-params)))
      (if (or (not (numberp exit-code)) (> exit-code 0))
          (progn
            (org-babel-eval-error-notify exit-code (buffer-string))
            (save-excursion
              (when (get-buffer org-babel-error-buffer-name)
                (with-current-buffer org-babel-error-buffer-name
                  (unless (derived-mode-p 'compilation-mode)
                    (compilation-mode))
                  ;; Compilation-mode enforces read-only, but Babel expects the buffer modifiable.
                  (setq buffer-read-only nil))))
            nil)
                                        ; return the contents of output file
        ;; (with-current-buffer output-file (buffer-string))
        (buffer-string)))))


;; This function should be used to assign any variables in params in
;; the context of the session environment.
(defun org-babel-prep-session:xslt (session params)
  "Prepare SESSION according to the header arguments specified in PARAMS."
  )

(defun org-babel-xslt-var-to-xslt (var)
  "Convert an elisp var into a string of xslt source code
specifying a var of the same value."
  (format "%S" var))

(defun org-babel-xslt-table-or-string (results)
  "If the results look like a table, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  )

(defun org-babel-xslt-initiate-session (&optional session)
  "If there is not a current inferior-process-buffer in SESSION then create.
Return the initialized session."
  (unless (string= session "none")
    ))

(provide 'ob-xslt)
;;; ob-xslt.el ends here
