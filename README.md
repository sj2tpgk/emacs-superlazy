# superlazy.el

Instant emacs startup by deferring configuration until first key press.

- [Installation](#installation)
- [Further config](#further-config)
- [How it works](#how-it-works)

## Installation
`init.el` will be renamed to `init2.el`.
* Shell one-liner: `cd ~/.emacs.d && curl https://raw.githubusercontent.com/sj2tpgk/emacs-superlazy/main/superlazy.el > superlazy.el && echo '(setq package-enable-at-startup nil)' >> early-init.el && mv -i init.el init2.el && echo -e '(load-file      (locate-user-emacs-file "superlazy.el"))\n(superlazy/load (locate-user-emacs-file "init2.el"))' >> init.el`

* Manual:
  1. Download `superlazy.el` into somewhere. (say `~/.emacs.d`)
  2. Rename your `init.el` to `init2.el`
  3. Create new `init.el` and put this:
     ```
     (load-file      (concat user-emacs-directory "superlazy.el")) ;; change path appropriately
     (superlazy/load (concat user-emacs-directory "init2.el"))
     ```
  4. Put this in `early-init.el`:
     ```
     (setq package-enable-at-startup nil)
     ```

Now `init2.el` will be loaded on first keypress.

## Further config
* You may want some of configs (e.g. themes) to be done before first keypress.
  They should be written in `init.el`:
  ```
  ;; init.el
  (load-theme 'wombat t) (setq frame-background-mode 'dark) ;; Load your favorite theme
  (add-hook 'prog-mode-hook 'display-line-numbers-mode)     ;; Line numbers
  (menu-bar-mode 0) (toolbar-mode 0)                        ;; No menu-bar and tool-bar
  (setq inhibit-startup-screen t)                           ;; No startup screen
  ```
* straight.el users should set this:
  ```
  ;; init.el
  (setq superlazy/package-initialize-on-keypress nil)
  ```

## How it works
* When `(superlazy/load FILE)` is evaluated, superlazy.el will first wait for the buffer to be rendered (`window-setup-hook`), then wait for first event by `(read-key-sequence nil)`.
* Use of `window-setup-hook` is important; otherwise it'll start waiting for first event *before* the buffer is rendered, which is not desirable.
* Due to `(setq package-enable-at-startup nil)` in early-init.el, package is not loaded until first event.
* The keypress is not missed by packages, for example, evil-mode, as superlazy.el sets `unread-command-events` properly.
