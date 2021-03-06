(use-package powerline)
(use-package airline-themes)
(use-package ucs-utils)

(require 'config_my_usability)

;; (powerline-center-theme)

;; (require 'airline-badwolf-theme)
;; (require 'airline-base16-gui-dark-theme)
;; (require 'airline-base16-shell-dark-theme)
;; (require 'airline-behelit-theme)
;; (require 'airline-dark-theme)
;; (require 'airline-distinguished-theme)
;; (require 'airline-durant-theme)
;; (require 'airline-hybridline-theme)
;; (require 'airline-kalisi-theme)
;; (require 'airline-kolor-theme)
;; (require 'airline-light-theme)
;; (require 'airline-luna-theme)
;; (require 'airline-molokai-theme)
;; (require 'airline-murmur-theme)
;; (require 'airline-papercolor-theme)
;; (require 'airline-powerlineish-theme)
;; (require 'airline-raven-theme)
;; (require 'airline-serene-theme)
;; (require 'airline-silver-theme)
;; (require 'airline-simple-theme)
;; (require 'airline-solarized-alternate-gui-theme)
;; (require 'airline-solarized-gui-theme)
;; (require 'airline-sol-theme)
;; (require 'airline-ubaryd-theme)
;; (require 'airline-understated-theme)
;; (require 'airline-wombat-theme)


;; Тормозной airline по умолчанию дёргает `git symbolic-ref --short
;; HEAD` на каждое изменение буфера.
(defvar -airline-get-vc--cache
  (make-hash-table :weakness 'key)
  "buffer -> (result . cached-until)")

(defcustom -airline-get-vc--timeout 3.0 "foobar" :type 'float)

(defun -airline-get-vc--around (old-fn &rest args)
  (let* ((time (current-time))
         (unixtime (+ (lsh (car time) 16) (cadr time)))
         (cache-key (current-buffer))
         (cache-cell (gethash cache-key -airline-get-vc--cache))
         (result (car cache-cell))
         (cached-until (cdr cache-cell)))
    (when (or (null cached-until) (< cached-until unixtime))
      (setq result (apply old-fn args))
      (puthash cache-key (cons result (+ unixtime -airline-get-vc--timeout))
               -airline-get-vc--cache))
    result))
(advice-add 'airline-get-vc :around '-airline-get-vc--around)


(defun my-flycheck-mode-line-status-text (oldfun &optional status)
  (let ((text-properties (text-properties-at 0 (apply oldfun status)))
        (param-tuple
         (pcase (or status flycheck-last-status-change)
           (`not-checked '("" . nil))
           (`no-checker '("-" . nil))
           (`running (cons (ucs-utils-string "hourglass with flowing sand") nil))
           (`errored (cons (ucs-utils-string "negative squared cross mark") nil))
           (`finished
            (let-alist (flycheck-count-errors flycheck-current-errors)
              (cond
               ((not (null .error)) (cons (ucs-utils-string "angry face") nil))
               ((not (null .warning)) (cons (ucs-utils-string "confused face") nil))
               (t (cons (ucs-utils-string "winking face") nil))))))))
    (let ((text (car param-tuple))
          (face (cdr param-tuple)))
      (when (not (null face))
        (setq text (apply propertize text (append text-properties 'face face))))
      text)))
(advice-add 'flycheck-mode-line-status-text :around 'my-flycheck-mode-line-status-text)


(defcustom -projectile-buffer-info--timeout 3.0 "foobar" :type 'float)

(defvar -projectile-buffer-info--cache
  (make-hash-table :weakness 'key)
  "buffer -> (<(<projectile-project-name> <relative-dir-path>) or nil> . <expiration unix time>)")


(defcustom mode-line-renamings
  (let ((hash (make-hash-table))
        (renamings `((projectile-mode . "")
                     (auto-revert-mode . "")
                     (helm-mode . "♚")
                     (company-mode . ,(ucs-utils-string "memo"))
                     (ggtags-mode . ,(ucs-utils-string "globe with meridians"))
                     (helm-gtags-mode . "")
                     (abbrev-mode . "D")
                     (ropemacs-mode . ,(ucs-utils-string "snake"))
                     (sphinx-doc-mode . "")
                     (smerge-mode . "⟗")
                     (auto-highlight-symbol-mode . "")
                     (yas-minor-mode . ""))))
    (mapcar (lambda (c) (puthash (car c) (cdr c) hash)) renamings)
    hash)
  "mode-symbol -> new text")

(defun -do-mode-line-renamings (minor-mode-alist)
  (mapcar (lambda (c)
            (let ((new-name (gethash (car c) mode-line-renamings nil)))
              (if new-name (list (car c) new-name) c)))
          minor-mode-alist))


;;; Должны быть установлены параметры:
;;;  '(uniquify-buffer-name-style (quote forward) nil (uniquify))
;;;  '(uniquify-strip-common-suffix nil)
(defun -projectile-buffer-info ()
  (let* ((time (current-time))
         (unixtime (+ (lsh (car time) 16) (cadr time)))
         (cache-key (current-buffer))
         (cache-cell (gethash cache-key -projectile-buffer-info--cache))
         (result (car cache-cell))
         (cached-until (cdr cache-cell)))
    (when (or (null cached-until) (< cached-until unixtime))
      (setq result
            (let* ((file-path (buffer-file-name))
                   (visible-part (buffer-name))
                   (project-dir (and (not (file-remote-p (or file-path default-directory)))
                                     (projectile-project-p)))
                   (result-part (when (and project-dir file-path)
                                  (concat (projectile-project-name)
                                          "/" (substring file-path (length project-dir))))))
              (when result-part
                (if (< (length visible-part) (length result-part))
                    (substring result-part 0 (- 0 (length visible-part)))
                  ""))))
      (puthash cache-key (cons result (+ unixtime -projectile-buffer-info--timeout))
               -projectile-buffer-info--cache))
    result))


(require 'powerline-adaptive)
(defun my-mode-line-format-adaptive ()
  (render-adaptive
   (let* ((active (powerline-selected-window-active))
          (separator-left (intern (format "powerline-%s-%s"
                                          (powerline-current-separator)
                                          (car powerline-default-separator-dir))))
          (separator-right (intern (format "powerline-%s-%s"
                                           (powerline-current-separator)
                                           (cdr powerline-default-separator-dir))))
          (mode-line-face (if active 'mode-line 'mode-line-inactive))

          (outer-face
           (if (powerline-selected-window-active) 'airline-normal-outer 'powerline-inactive1))

          (inner-face
           (if (powerline-selected-window-active) 'airline-normal-inner 'powerline-inactive2))

          (center-face
           (if (powerline-selected-window-active) 'airline-normal-center 'powerline-inactive2))

          (outer-space `((value . ,(powerline-raw " " outer-face))
                         (priority . 50)))

          (inner-space `((value . ,(powerline-raw " " inner-face))
                         (priority . 50)))

          (center-space `((value . ,(powerline-raw " " center-face))
                          (priority . 50))))
     (list
      ;; Mule Info
      (when powerline-display-mule-info
        `((value . ,(powerline-raw mode-line-mule-info outer-face 'l))
          (priority . 10)))

      ;; Modified string
      `((value . ,(powerline-raw "%*" outer-face 'l))
        (priority . 100))

      ;; Separator >
      outer-space
      `((value . ,(funcall separator-left outer-face inner-face)))
      inner-space

      ;; LN character, Current Line and % location in file
      `((value . ,(powerline-raw (char-to-string airline-utf-glyph-linenumber) inner-face))
        (priority . 50))
      `((value . ,(powerline-raw "%l:%c" inner-face))
        (priority . 75))

      ;; % location in file
      `((value . ,(powerline-raw "(%p)" inner-face 'r))
        (priority . 60))

      ;; Buffer Size
      `((value . ,(powerline-raw "%I" inner-face))
        (priority . 60))

      ;; Separator >
      inner-space
      `((value . ,(funcall separator-left inner-face center-face)))
      center-space

      ;; Projectile
      (let ((projectile-info (-projectile-buffer-info)))
        (when projectile-info
          `(((value . ,(powerline-raw (ucs-utils-string "open file folder") center-face))
             (priority . 65))
            ((value . ,(powerline-raw projectile-info center-face))
             (priority . 65)))))

      ;; Buffer ID
      `((value . ,(powerline-raw "%b" center-face)))

      ;; Narrow if appropriate
      `((value . ,(powerline-raw "%n" center-face)))

      ;; Spacer
      `((value . ,(powerline-raw "\t" center-face)))

      ;; (when (boundp 'erc-modified-channels-object)
      ;;   (powerline-raw erc-modified-channels-object center-face 'l))

      ;; Separator <
      center-space
      `((value . ,(funcall separator-right center-face inner-face)))
      inner-space

      ;; Global mode
      `((value . ,(car global-mode-string))
        (priority . 90))

      ;; Major Mode
      `((value . ,(powerline-raw
                   (propertize mode-name
                               'mouse-face 'mode-line-highlight
                               'help-echo "Major mode\n\ mouse-1: Display major mode menu\n\ mouse-2: Show help for major mode\n\ mouse-3: Toggle minor modes"
                               'local-map (let ((map (make-sparse-keymap)))
                                            (define-key map [mode-line down-mouse-1]
                                              `(menu-item ,(purecopy "Menu Bar") ignore
                                                          :filter (lambda (_) (mouse-menu-major-mode-map))))
                                            (define-key map [mode-line mouse-2] 'describe-mode)
                                            (define-key map [mode-line down-mouse-3] mode-line-mode-menu)
                                            map))
                   inner-face))
        (priority . 100))

      (when mode-line-process
        `((value . ,(powerline-raw (cond
                                    ((symbolp mode-line-process) (symbol-value mode-line-process))
                                    ((listp mode-line-process) (format-mode-line mode-line-process))
                                    (t mode-line-process))
                                   inner-face))
          (priority . 100)))

      ;; Subseparator <
      inner-space
      `((value . ,(powerline-raw (char-to-string airline-utf-glyph-subseparator-right) inner-face))
        (priority . 75))
      inner-space

      ;; Minor Modes
      `((value . ,(powerline-raw (format-mode-line (-do-mode-line-renamings minor-mode-alist)) inner-face))
        (priority . 75))

      ;; Separator <
      inner-space
      `((value . ,(powerline-raw (funcall separator-right inner-face outer-face) outer-face)))

      ;; Git Branch
      `((value . ,(or (powerline-raw (airline-get-vc) outer-face) ""))
        (priority . 55))))))


(defun my-mode-line-format ()
  (let* ((active (powerline-selected-window-active))
         (width (window-total-width))
         (expance (< 100 width))
         (tight (> 70 width))
         (separator-left (intern (format "powerline-%s-%s"
                                         (powerline-current-separator)
                                         (car powerline-default-separator-dir))))
         (separator-right (intern (format "powerline-%s-%s"
                                          (powerline-current-separator)
                                          (cdr powerline-default-separator-dir))))
         (mode-line-face (if active 'mode-line 'mode-line-inactive))

         (outer-face
          (if (powerline-selected-window-active) 'airline-normal-outer 'powerline-inactive1))

         (inner-face
          (if (powerline-selected-window-active) 'airline-normal-inner 'powerline-inactive2))

         (center-face
          (if (powerline-selected-window-active) 'airline-normal-center 'powerline-inactive2))

         ;; Left Hand Side
         (lhs-mode
          (list
           ;; Mule Info
           (when powerline-display-mule-info
             (powerline-raw mode-line-mule-info outer-face 'l))

           ;; Modified string
           (powerline-raw "%*" outer-face 'l)
           ;; Separator >
           (when expance (powerline-raw " " outer-face))
           (funcall separator-left outer-face inner-face)))

         (lhs-rest (list
                    ;; ;; Separator >
                    ;; (powerline-raw (char-to-string #x2b81) inner-face 'l)

                    ;; Eyebrowse current tab/window config
                    (if (featurep 'eyebrowse)
                        (powerline-raw (concat " " (eyebrowse-mode-line-indicator)) inner-face))

                    ;; LN character, Current Line and % location in file
                    (powerline-raw
                     (concat
                      (if expance (char-to-string airline-utf-glyph-linenumber) "")
                      "%l:%c")
                     inner-face 'l)

                    ;; % location in file
                    (when expance (powerline-raw "(%p)" inner-face 'r))

                    ;; Buffer Size
                    (when (and expance powerline-display-buffer-size)
                      (powerline-buffer-size inner-face 'l))

                    ;; Separator >
                    (when expance (powerline-raw " " inner-face))
                    (funcall separator-left inner-face center-face)
                    (when expance (powerline-raw " " center-face))

                    ;; Directory
                    ;; (when (eq airline-display-directory 'airline-directory-shortened)
                    ;;   (powerline-raw (airline-shorten-directory default-directory airline-shortened-directory-length) center-face 'l))
                    ;; (when (eq airline-display-directory 'airline-directory-full)
                    ;;   (powerline-raw default-directory center-face 'l))
                    ;; (when (eq airline-display-directory nil)
                    ;;   (powerline-raw " " center-face))

                    ;; Projectile
                    (when (not (file-remote-p default-directory))
                      (let ((project (projectile-project-name)))
                        (when (not (or tight (equal project "-")))
                          (powerline-raw
                           (concat (if expance (ucs-utils-string "open file folder") "")
                                   project
                                   (if expance " " "")
                                   (char-to-string airline-utf-glyph-subseparator-left)
                                   (if expance " " ""))
                           center-face))))

                    ;; Buffer ID
                    ;; (powerline-buffer-id center-face)
                    (powerline-raw "%b" center-face)

                    ;; Narrow if appropriate
                    (powerline-raw "%n" center-face)

                    ;; ;; Separator >
                    ;; (powerline-raw " " center-face)
                    ;; (funcall separator-left mode-line face1)

                    (when (boundp 'erc-modified-channels-object)
                      (powerline-raw erc-modified-channels-object center-face 'l))

                    ;; ;; Separator <
                    ;; (powerline-raw " " face1)
                    ;; (funcall separator-right face1 face2)
                    ))

         (lhs (append lhs-mode lhs-rest))

         ;; Right Hand Side
         (rhs (if tight
                  ;; Separator <
                  (list (powerline-raw (ucs-utils-string "black scissors") center-face)
                        (funcall separator-right center-face outer-face))

                (list (powerline-raw global-mode-string center-face 'r)

                      ;; Separator <
                      (when expance (powerline-raw " " center-face))
                      (funcall separator-right center-face inner-face)

                      ;; Major Mode
                      (powerline-major-mode inner-face 'l)
                      (powerline-process inner-face)

                      ;; Subseparator <
                      (powerline-raw (char-to-string airline-utf-glyph-subseparator-right) inner-face 'l)

                      ;; Minor Modes
                      (powerline-raw (format-mode-line mode-line-modes) inner-face)
                      ;; (powerline-minor-modes inner-face 'l)
                      ;; (powerline-narrow center-face 'l)

                      (powerline-raw " " inner-face)

                      ;; Separator <
                      (funcall separator-right inner-face outer-face)

                      ;; Git Branch
                      (when expance (powerline-raw (airline-get-vc) outer-face))

                      (powerline-raw " " outer-face)
                      ))
              ))

    ;; Combine Left and Right Hand Sides
    (concat (powerline-render lhs)
            (powerline-fill center-face (powerline-width rhs))
            (powerline-render rhs))))


(setq-default mode-line-format '("%e" (:eval (my-mode-line-format-adaptive))))


(require 'mytheme2017)
;; (load-theme 'mytheme2017)

(powerline-reset)
(provide 'config_my_powerline)
