(require 'use-package)
(require 'general)
(require 'conf/common)

(use-package evil
  :demand t
  :defines my-evil-join

  :general
  (:keymaps 'emacs
   "C-w" 'evil-window-map)

  (my-map
    "k w" 'evil-window-delete

    "w k" 'evil-window-up
    "w j" 'evil-window-down
    "w h" 'evil-window-left
    "w l" 'evil-window-right)

  (:keymaps 'insert
   "C-y" 'my-evil-insert-mode-paste

   "C-u" 'my-kill-line
   "C-l" 'move-end-of-line)

  (:keymaps 'visual
   ">" 'visual-shift-right
   "<" 'visual-shift-left)

  (:keymaps 'normal
   "<" nil
   ">" nil

   ;; still able to shift things in normal mode
   "< <" 'evil-shift-left-line
   "> >" 'evil-shift-right-line

   "g p" 'exchange-point-and-mark

   "j" 'evil-next-visual-line
   "k" 'evil-previous-visual-line

   "M-l" 'my-clear-search
   "M-o" 'my-evil-open-in-between

   "C-k" 'evil-scroll-up
   "C-j" 'evil-scroll-down)

  (:keymaps 'evil-window-map
   "<left>" 'winner-undo
   "u" 'winner-undo

   "<right>" 'winner-redo
   "r" 'winner-redo

   "m k" 'buf-move-up
   "m j" 'buf-move-down
   "m h" 'buf-move-left
   "m l" 'buf-move-right)

  :init
  ;; don't auto-copy visual selections
  (fset 'evil-visual-update-x-selection 'ignore)

  (setq evil-want-C-w-in-emacs-state t
        evil-text-object-change-visual-type nil

        evil-search-module 'evil-search

        evil-want-C-w-delete t)

  (setq-default evil-symbol-word-search t
                evil-shift-width 2
                evil-shift-round nil)

  (with-eval-after-load 'company
    (defun my-evil-company (arg)
      (call-interactively 'company-complete))

    (setq evil-complete-next-func #'my-evil-company
          evil-complete-previous-func #'my-evil-company))

  (add-hook 'after-init-hook 'evil-mode)

  :config
  (eval-when-compile
    (require 'evil-macros)
    (require 'evil-types))

  ;; FIXME
  ;; when done on line:
  ;;     (insert "\n#endif  // " ident)))))
  ;; it modifies the string and becomes:
  ;;     (insert "\n#endif // " ident)))))
  ;;
  ;; if joined lines are comments, remove delimiters
  (evil-define-operator my-evil-join (beg end)
    "Join the selected lines."
    :motion evil-line
    (let* ((count (count-lines beg end))
           ;; we join pairs at a time
           (count (if (> count 1) (1- count) count))
           ;; the mark at the middle of the joined pair of lines
           (fixup-mark (make-marker)))
      (dotimes (var count)
        (if (and (bolp) (eolp))
            (join-line 1)
          (let* ((end (line-beginning-position 3))
                 (fill-column (1+ (- end beg))))
            ;; save the mark at the middle of the pair
            (set-marker fixup-mark (line-end-position))
            ;; join it via fill
            (fill-region-as-paragraph beg end)
            ;; jump back to the middle
            (goto-char fixup-mark)
            ;; context-dependent whitespace fixup
            (fixup-whitespace))))
      ;; remove the mark
      (set-marker fixup-mark nil)))

  (with-eval-after-load 'solarized
    (eval-when-compile
      (require 'solarized))

    (solarized-with-color-variables 'light
      (setq evil-normal-state-cursor `(,blue-l box)
            evil-insert-state-cursor `(,green-l box)
            evil-visual-state-cursor `(,magenta-l box)
            evil-replace-state-cursor `(,red-l (hbar . 4))
            evil-operator-state-cursor `((hbar . 6))
            evil-emacs-state-cursor `(,red-l box))))

  ;; if the point is in a comment that has non-whitespace content, delete up
  ;; until the beginning of the comment. if already at the beginning of the
  ;; comment, delete up to the indentation point. if already at the indentation
  ;; point, delete to the beginning of the line
  (defun my-kill-line ()
    (interactive)
    (let* ((starts
            (-non-nil
             ;; add comment-start-regexps to this as needed
             `("\\s<"
               ,(when (bound-and-true-p comment-start)
                  (regexp-quote (s-trim-right comment-start)))
               ,(bound-and-true-p c-comment-start-regexp))))
           (comment-starts (s-join "\\|" starts))
           (start-re (concat "\\(" comment-starts "\\)")))
      (if (and
           ;; in a comment
           (elt (syntax-ppss) 4)
           ;; we're in a single line comment
           (looking-back (concat start-re ".+")
                         (line-beginning-position))
           ;; not right after starting delimiter
           (not (looking-back (concat start-re "\\s-?")
                              (line-beginning-position))))
          (let ((beg (point)))
            (beginning-of-visual-line)
            ;; go after comment position
            (re-search-forward
             (concat ".*" start-re "\\s-?")
             (line-end-position))
            ;; kill rest of line
            (kill-region (point) beg))
        (if (looking-back "^[[:space:]]+")
            ;; kill entire line
            (kill-line 0)
          ;; kill up to indentation point
          (let ((beg (point)))
            (when (not (equal beg (line-beginning-position)))
              (back-to-indentation)
              (kill-region beg (point))))))))

  (defun my-evil-insert-mode-paste ()
    (interactive)
    (evil-paste-before 1)
    (forward-char))

  (evil-define-operator visual-shift-left (beg end type)
    "shift text to the left"
    :keep-visual t
    :motion evil-line
    :type line
    (interactive "<r><vc>")
    (call-interactively 'evil-shift-left)
    (evil-normal-state)
    (evil-visual-restore))

  (evil-define-operator visual-shift-right (beg end type)
    "shift text to the right"
    :keep-visual t
    :motion evil-line
    :type line
    (interactive "<r><vc>")
    (call-interactively 'evil-shift-right)
    (evil-normal-state)
    (evil-visual-restore))

  (defun my-evil-open-in-between ()
    (interactive)

    (evil-with-single-undo
      (evil-open-below 1)
      (evil-maybe-remove-spaces t)
      (evil-open-above 1)))

  (defun my-clear-search ()
    (interactive)
    (evil-ex-nohighlight)
    (force-mode-line-update)))

(use-package evil-indent-plus
  :after evil
  :config
  (evil-indent-plus-default-bindings))

(use-package evil-quickscope
  :after evil
  :config
  (global-evil-quickscope-mode 1))

(use-package evil-lion
  :after evil
  :config
  (evil-lion-mode))

(use-package evil-textobj-anyblock
  :general
  (:keymaps 'inner
   "b" 'evil-textobj-anyblock-inner-block)

  (:keymaps 'outer
   "b" 'evil-textobj-anyblock-a-block))

(use-package evil-anzu
  :after evil)

(use-package evil-commentary
  :diminish evil-commentary-mode
  :after evil

  :config
  (evil-commentary-mode))

(use-package evil-exchange
  :after evil
  :config
  (evil-exchange-install))

(use-package evil-numbers
  :general
  (:keymaps '(normal visual)
   "<kp-subtract>" 'evil-numbers/dec-at-pt
   "<kp-add>" 'evil-numbers/inc-at-pt))

(use-package evil-surround
  :after evil
  :config
  (setq-default
   evil-surround-pairs-alist
   (cons '(? . ("" . "")) evil-surround-pairs-alist))

  (global-evil-surround-mode 1))

(use-package evil-visualstar
  :after evil
  :config
  (global-evil-visualstar-mode))

(use-package evil-args
  :general
  (:keymaps 'normal
   "K" 'evil-jump-out-args

   "> a" 'evil-arg-swap-forward
   "< a" 'evil-arg-swap-backward)

  (:keymaps 'inner
   "a" 'evil-inner-arg)

  (:keymaps 'outer
   "a" 'evil-outer-arg)

  (:keymaps '(normal motion)
   "L" 'evil-forward-arg
   "H" 'evil-backward-arg)

  :config
  (defun evil-arg-swap-forward ()
    (interactive)
    (apply 'evil-exchange (evil-inner-arg))
    (call-interactively 'evil-forward-arg)
    (apply 'evil-exchange (evil-inner-arg)))

  (defun evil-arg-swap-backward ()
    (interactive)
    (apply 'evil-exchange (evil-inner-arg))
    (evil-forward-arg 1)
    (evil-backward-arg 2)
    (apply 'evil-exchange (evil-inner-arg))))

(use-package evil-goggles
  :after evil

  :init
  (setq evil-goggles-duration 0.100

        ;; to disable the hint when pasting:
        ;; evil-goggles-enable-paste nil

        ;; list of all on/off variables, their default value is `t`:
        ;;
        ;; evil-goggles-enable-delete
        ;; evil-goggles-enable-indent
        ;; evil-goggles-enable-yank
        ;; evil-goggles-enable-join
        ;; evil-goggles-enable-fill-and-move
        ;; evil-goggles-enable-paste
        ;; evil-goggles-enable-shift
        ;; evil-goggles-enable-surround
        ;; evil-goggles-enable-commentary
        ;; evil-goggles-enable-replace-with-register
        ;; evil-goggles-enable-set-marker
        )

  :config
  (evil-goggles-mode))

(provide 'conf/evil)
