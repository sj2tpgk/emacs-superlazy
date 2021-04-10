;;; superlazy.el --- load config on first keypress  -*- lexical-binding: t; -*-

;;; Commentary:

;; Load config on first keypress.
;;
;; Setup:
;;
;; 1. In early-init.el:
;;    -----------------
;;    (setq package-enable-at-startup nil)
;;
;; 2. Rename init.el --> init2.el
;;
;; 3. Create new init.el:
;;    -------------------
;;    (load-file      (locate-user-emacs-file "superlazy.el"))
;;    (superlazy/load (locate-user-emacs-file "init2.el"))
;;
;;
;; Further setup:
;;  - You might want to set these in init.el:
;;
;;    init.el
;;    ----------
;;    (setq inhibit-startup-screen t)                       ;; No startup screen
;;    (menu-bar-mode 0) (toolbar-mode 0)                    ;; No menu-bar and tool-bar
;;    (add-hook 'prog-mode-hook 'display-line-numbers-mode) ;; Line numbers
;;    ;; Load your favorite theme
;;    (load-theme 'wombat t)
;;    (setq frame-background-mode 'dark)
;;    (custom-set-faces '(cursor ((t (:background "#ddd" :foreground "#111")))))

;;; Code:

(defcustom superlazy/package-initialize-on-keypress t
  "Users of alternative package managers (straight.el etc.) should set this to nil."
  :type '(boolean) :group 'superlazy)

(defvar superlazy/gct-save    nil "Internal var.")
(defvar superlazy/fnha-save   nil "Internal var.")
(defvar superlazy/first-event nil "Internal var.")
(defvar superlazy/has-run     nil "Internal var.")

(defun superlazy/load-silently (file)
  "Silently load FILE."
  (load (expand-file-name file) nil t t))

(defun superlazy/load-1 (&rest files)
  "Do loading FILES."

  (setq superlazy/gct-save      gc-cons-threshold
	superlazy/fnha-save     file-name-handler-alist
	gc-cons-threshold       256000000
	file-name-handler-alist nil)

  ;; initialize package.el (not recommended for straight.el users)
  (when superlazy/package-initialize-on-keypress
    (package-initialize))

  (dolist (f files) (superlazy/load-silently f))

  ;; Set major modes in each buffer (for nim etc.)
  (dolist (b (buffer-list)) (with-current-buffer b (normal-mode)))

  ;; Revert GC thresh and alist
  (when (= gc-cons-threshold 256000000) (setq gc-cons-threshold superlazy/gct-save))
  (when (null file-name-handler-alist)  (setq file-name-handler-alist superlazy/fnha-save))
  )


(defun superlazy/load (&rest files)
  "Setup lazy loading for FILES."

  (if (and (boundp 'superlazy/has-run) superlazy/has-run)
      (apply 'superlazy/load-1 files)
    (let (f) ;; letrec
      (setq f (lambda ()
                (remove-hook 'window-setup-hook f)
                (setq superlazy/first-event (read-key-sequence nil))
                (apply 'superlazy/load-1 files)
                ;; Replay key
                (setq unread-command-events   (listify-key-sequence superlazy/first-event))))
      (add-hook 'window-setup-hook f)))

  (setq superlazy/has-run t)

  ;; New: saving the result of (read-key-sequence) and assign it to
  ;;      unread-command-events is fine for lazy loading.

  ;; Useful links :
  ;;   - Startup summary : https://www.gnu.org/software/emacs/manual/html_node/elisp/Startup-Summary.html
  ;;   - (read-key-sequence) : https://www.gnu.org/software/emacs/manual/html_node/elisp/Key-Sequence-Input.html
  ;;   - (read-event) etc. : https://www.gnu.org/software/emacs/manual/html_node/elisp/Reading-One-Event.html
  ;;   - Simulating keys : https://emacs.stackexchange.com/a/2471
  ;;   - unread-command-events : https://www.gnu.org/software/emacs/manual/html_node/elisp/Event-Input-Misc.html
  ;;   - Command loop : https://www.gnu.org/software/emacs/manual/html_node/elisp/Command-Overview.html
  ;;   - Set major modes automatically : https://www.gnu.org/software/emacs/manual/html_node/elisp/Auto-Major-Mode.html

  ;; after-init-hook   : before deciding *scratch* or startup screen
  ;; post-command-hook : after ready to accept key input
  ;; find-file-hook    : file load; before buffer is rendered
  ;; window-setup-hook : after buffer is rendered
  ;; pre-command-hook  : when first key is pressed

  ;; Loading evil on "pre-command-hook" doesn't work well
  ;;   - Command for the first key event (say "i") is decided before evil is
  ;;   - loaded: "self-insert-command" runs instead of "evil-insert-state"
  ;;   - An attempt: call "(undo)" to cancel "self-insert-command"
  ;;   - But how can we determine corresponding command to be "evil-insert-state"?

  ;; So we want to avoid package manager startup just to load evil.
  ;;   - But "(require 'evil)" on "emacs-startup-hook" is not fast at all.
  ;;   - This also breaks use-package's reproductivity.

  ;; Loading evil (and straight.el) on "post-command-hook" doesn't feel very fast.
  ;;   - It seems evil is loaded BEFORE buffer is fully rendered.
  ;;   - It'd be better if there's  "after-buffer-render-hook".

  )

(provide 'superlazy)
;;; superlazy.el ends here
