(require 'use-package)

(use-package saveplace
  :ensure nil
  :defines save-place-file
  :init
  (setq save-place-file (blaenk/cache-dir "saved-places")))

(use-package bookmark
  :ensure nil
  :defines bookmark-default-file
  :init
  (setq bookmark-default-file (blaenk/cache-dir "bookmarks")))

(use-package recentf
  :ensure nil
  :defines recentf-save-file
  :init
  (setq recentf-save-file (blaenk/cache-dir "recentf"))
  (setq recentf-max-saved-items 50)
  :config
  (global-set-key (kbd "C-x C-r") 'helm-recentf)
  (recentf-mode 1)
  ;; save recent files every 5 minutes
  ;; (run-at-time nil (* 5 60) 'recentf-save-list)
  )

(use-package savehist
  :ensure nil
  :init
  (setq savehist-save-minibuffer-history 1)
  (setq savehist-file (blaenk/cache-dir "history")))

(use-package ido
  :ensure nil
  :defines ido-save-directory-list-file
  :init
  (setq ido-save-directory-list-file (blaenk/cache-dir "ido.last")))

(use-package eshell
  :ensure nil
  :defines eshell-directory
  :init
  (setq eshell-directory (blaenk/cache-dir "eshell")))

(use-package apropos
 :ensure nil
 :defines apropos-do-all
 :init
 (setq apropos-do-all t))

;; NOTE gdb also requires argument `-i=mi`
(use-package gdb-mi
 :ensure nil
  :defines (gdb-many-windows gdb-show-main)
  :init
  (setq gdb-many-windows t)
  (setq gdb-show-main t))

(use-package paren
  :ensure nil
  :defines show-paren-delay
  :init
  (setq show-paren-delay 0))

(use-package shell
  :ensure nil
  :defines explicit-shell-file-name
  :init
  (setq explicit-shell-file-name "/usr/bin/zsh"))

(use-package whitespace
  :ensure nil
  :defer t
  :diminish whitespace-mode

  :init
  ;; NOTE
  ;; lines-tail to see which lines go beyond max col
  (setq whitespace-style
        '(face indentation trailing empty space-after-tab
          space-before-tab tab-mark))
  (setq whitespace-line-column nil)
  (add-hook 'prog-mode-hook 'whitespace-mode))

(use-package js
  :ensure nil
  :init
  (setq js-indent-level 2))

(use-package sh-script
  :ensure nil
  :mode ("\\.zsh\\(rc\\)?\\'" . sh-mode)
  :init
  (setq sh-learn-basic-offset t)
  (setq sh-basic-offset 2)
  (setq sh-indentation 2)

  :config
  (add-hook 'sh-mode-hook
            (lambda ()
              (if (string-match "\\.zsh\\(rc\\)?$" (or (buffer-file-name) ""))
                  (sh-set-shell "zsh")))))

(use-package python
  :ensure nil
  :defer t

  :config
  ;; TODO other PEP8 stuff
  (add-hook 'python-mode-hook (lambda () (setq fill-column 79)))

  (let ((ipython (executable-find "ipython")))
    (when ipython
      (setq python-shell-interpreter ipython))))

(use-package semantic
  :ensure nil
  :defines
  semanticdb-default-save-directory
  :init
  (setq semanticdb-default-save-directory (blaenk/cache-dir "semanticdb"))

  :config
  (require 'semantic/db-mode)
  (global-semanticdb-minor-mode 1)
  (global-semantic-idle-scheduler-mode 1)
  (semantic-mode 1))

(use-package cc-mode
  :ensure nil
  :config
  (defun blaenk/insert-include-guard ()
    (interactive)
    (let* ((project-root (when (projectile-project-p)
                           (projectile-project-root)))
           (buf-name (or (buffer-file-name) (buffer-name)))
           (name (if project-root
                     (replace-regexp-in-string
                      (regexp-quote project-root) ""
                      buf-name)
                   buf-name))
           (filtered (replace-regexp-in-string
                      (regexp-opt '("source/" "src/")) "" name))
           (ident (concat
                   (upcase
                    (replace-regexp-in-string "[/.-]" "_" filtered))
                   "_")))
      (save-excursion
        (goto-char (point-min))
        (insert "#ifndef " ident "\n")
        (insert "#define " ident "\n\n")
        (goto-char (point-max))
        (insert "\n#endif  // " ident))))

  (add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
  (push '(nil "^TEST\\(_F\\)?(\\([^)]+\\))" 2) imenu-generic-expression))

(use-package tramp
  :ensure nil
  :defer t

  :init
  (eval-after-load 'tramp '(setenv "SHELL" "/bin/bash")))

(use-package saveplace
  :ensure nil
  :init
  (setq-default save-place t))

(use-package imenu
  :ensure nil
  :defer t

  :init
  (defun imenu-use-package ()
    (add-to-list 'imenu-generic-expression
                 '("Used Packages"
                   "\\(^\\s-*(use-package +\\)\\(\\_<.+\\_>\\)" 2)))

  (add-hook 'emacs-lisp-mode-hook 'imenu-use-package))

(use-package ediff
  :ensure nil
  :init
  (setq ediff-split-window-function 'split-window-horizontally)
  (setq ediff-window-setup-function 'ediff-setup-windows-plain)

  :config
  (defvar blaenk/ediff-last-windows nil)

  (defun blaenk/is-fullscreen ()
    (memq (frame-parameter nil 'fullscreen) '(fullscreen fullboth)))

  (defun blaenk/go-fullscreen ()
    (interactive)
    (set-frame-parameter nil 'fullscreen 'fullboth))

  (defun blaenk/un-fullscreen ()
    (set-frame-parameter nil 'fullscreen nil))

  (defun blaenk/toggle-ediff-wide-display ()
    (require 'ediff-util)
    "Turn off wide-display mode (if was enabled) before quitting ediff."
    (when ediff-wide-display-p
      (ediff-toggle-wide-display)))

  (defun blaenk/ediff-prepare ()
    (setq blaenk/ediff-last-windows (current-window-configuration))
    (turn-off-hideshow)
    (turn-off-fci-mode)
    (visual-line-mode -1)
    (whitespace-mode -1))

  (defun blaenk/ediff-start ()
    (interactive)
    (blaenk/go-fullscreen))

  (defun blaenk/ediff-quit ()
    (interactive)
    (set-window-configuration blaenk/ediff-last-windows)
    (blaenk/toggle-ediff-wide-display)
    (blaenk/un-fullscreen))

  (add-hook 'ediff-prepare-buffer-hook 'blaenk/ediff-prepare)
  (add-hook 'ediff-startup-hook 'blaenk/ediff-start)
  (add-hook 'ediff-suspend-hook 'blaenk/ediff-quit 'append)
  (add-hook 'ediff-quit-hook 'blaenk/ediff-quit 'append))

;; TODO
;; this also cons mode-line
;; need a more robust way of reformatting mode-line
;; perhaps advice on force-mode-line-update?
(use-package eldoc
  :ensure nil
  :defer t

  :init
  (setq eldoc-idle-delay 0.1)

  :config
  (add-hook 'eval-expression-minibuffer-setup-hook 'eldoc-mode))

(use-package bug-reference
  :ensure nil
  :defer t

  :init
  (setq bug-reference-bug-regexp "\\(\
[Ii]ssue ?#\\|\
[Bb]ug ?#\\|\
[Pp]atch ?#\\|\
RFE ?#\\|\
PR [a-z-+]+/\
\\)\\([0-9]+\\(?:#[0-9]+\\)?\\)")

  (add-hook 'prog-mode-hook #'bug-reference-prog-mode)
  (add-hook 'prog-mode-hook #'bug-reference-prog-mode))

(use-package goto-addr
  :ensure nil
  :defer t

  :init
  (add-hook 'prog-mode-hook #'goto-address-prog-mode)
  (add-hook 'text-mode-hook #'goto-address-mode))

(use-package dired
  :ensure nil
  :defer t

  :init
  (setq dired-auto-revert-buffer t)
  (setq dired-listing-switches "-alhF")

  (when (or (memq system-type '(gnu gnu/linux))
            (string= (file-name-nondirectory insert-directory-program) "gls"))
    (setq dired-listing-switches
          (concat dired-listing-switches " --group-directories-first -v"))))

(use-package dired-x
  :ensure nil
  :bind
  (("C-x C-j" . dired-jump))

  :config
  (setq dired-omit-verbose nil)
  (add-hook 'dired-mode-hook #'dired-omit-mode)

  (when (eq system-type 'darwin)
    (setq dired-guess-shell-gnutar "tar")))

(ignore-errors
  (require 'ansi-color)
  (defun colorize-compilation-buffer ()
    (when (eq major-mode 'compilation-mode)
      (ansi-color-apply-on-region compilation-filter-start (point-max))))

  (add-hook 'compilation-filter-hook 'colorize-compilation-buffer))

(use-package compile
  :ensure nil
  :init
  (setq compilation-scroll-output 'first-error)
  (setq compilation-ask-about-save nil)
  (setq compilation-set-skip-threshold 0)
  (setq compilation-always-kill t))

(use-package hl-line
  :ensure nil
  :init
  (setq hl-line-sticky-flag t)
  :config
  (add-hook 'prog-mode-hook 'hl-line-mode))

(use-package hideshow
  :ensure nil
  :config
  (add-hook 'prog-mode-hook 'hs-minor-mode))

(use-package flyspell
  :ensure nil
  :config
  (add-hook 'text-mode-hook 'flyspell-mode)
  (add-hook 'prog-mode-hook 'flyspell-prog-mode)

  (defun flyspell-goto-previous-error (arg)
    "Go to arg previous spelling error."
    (interactive "p")
    (while (not (= 0 arg))
      (let ((pos (point))
            (min (point-min)))
        (if (and (eq (current-buffer) flyspell-old-buffer-error)
                 (eq pos flyspell-old-pos-error))
            (progn
              (if (= flyspell-old-pos-error min)
                  ;; goto beginning of buffer
                  (progn
                    (message "Restarting from end of buffer")
                    (goto-char (point-max)))
                (backward-word 1))
              (setq pos (point))))
        ;; seek the next error
        (while (and (> pos min)
                    (let ((ovs (overlays-at pos))
                          (r '()))
                      (while (and (not r) (consp ovs))
                        (if (flyspell-overlay-p (car ovs))
                            (setq r t)
                          (setq ovs (cdr ovs))))
                      (not r)))
          (backward-word 1)
          (setq pos (point)))
        ;; save the current location for next invocation
        (setq arg (1- arg))
        (setq flyspell-old-pos-error pos)
        (setq flyspell-old-buffer-error (current-buffer))
        (goto-char pos)
        (if (= pos min)
            (progn
              (message "No more miss-spelled word!")
              (setq arg 0))))))

  (defun check-previous-spelling-error ()
    "Jump to previous spelling error and correct it"
    (interactive)
    (push-mark-no-activate)
    (flyspell-goto-previous-error 1)
    (call-interactively 'helm-flyspell-correct))

  (defun check-next-spelling-error ()
    "Jump to next spelling error and correct it"
    (interactive)
    (push-mark-no-activate)
    (flyspell-goto-next-error)
    (call-interactively 'helm-flyspell-correct))

  (defun push-mark-no-activate ()
    "Pushes `point' to `mark-ring' and does not activate the region
 Equivalent to \\[set-mark-command] when \\[transient-mark-mode] is disabled"
    (interactive)
    (push-mark (point) t nil)
    (message "Pushed mark to ring")))