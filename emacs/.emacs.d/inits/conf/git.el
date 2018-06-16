(require 'straight)
(require 'conf/common)
(require 'use-package)
(require 'general)

(use-package gist
  :general
  (my-map :infix "g g"
    "" '(:ignore t :which-key "gist")
    "s" 'gist-region-or-buffer-private
    "p" 'gist-region-or-buffer
    "l" 'gist-list)

  :init
  (setq gist-ask-for-description t
        gist-ask-for-filename t
        gist-list-format
        '((created "Created" 15 nil
                   "%D %R")
          (visibility "Visibility" 8 nil
                      (lambda (public)
                        (or (and public "public")
                            "private")))
          (files "Files" 0 nil
                 (lambda (names)
                   (mapconcat 'identity names ", ")))))

  (unless my--is-within-vm
    (setq gist-view-gist t)))


(use-package git-commit-insert-issue
  :defer t

  :init
  (add-hook 'git-commit-mode-hook #'git-commit-insert-issue-mode))

(use-package bug-reference-github
  :defer t

  :init
  (add-hook 'find-file-hook #'bug-reference-github-set-url-format))

(use-package browse-at-remote
  :general
  (my-map "o g" 'browse-at-remote-kill)

  :init
  (setq browse-at-remote-prefer-symbolic nil))

(use-package git-timemachine :defer t)

(use-package github-clone :defer t)

(use-package git-commit
  :init
  (setq git-commit-summary-max-length 50)

  (defun my--company-dabbrev-ignore-except-magit-diff (buffer)
    (let ((name (buffer-name)))
      (and (string-match-p "\\`[ *]" name)
           (not (string-match-p "\\*magit-diff:" name)))))

  (defun my--git-commit-setup-hook ()
    (setq-local fill-column 72)

    (with-eval-after-load 'yasnippet
      (yas-activate-extra-mode 'git-commit-mode))

    ;; This enables us to use company completion inside of the git-commit message
    ;; buffer to complete things from the accompanying diff buffer. This is very
    ;; useful when talking about affected functions, variables, etc.
    (setq-local company-dabbrev-code-modes '(text-mode magit-diff-mode))
    (setq-local company-dabbrev-ignore-buffers
                #'my--company-dabbrev-ignore-except-magit-diff))

  (add-hook 'git-commit-setup-hook #'my--git-commit-setup-hook)
  (add-hook 'git-commit-setup-hook #'git-commit-turn-on-flyspell)
  (add-hook 'git-commit-setup-hook #'fci-mode)

  :config
  (with-eval-after-load 'evil
    (evil-set-initial-state #'git-commit-mode 'insert))

  (add-to-list 'git-commit-style-convention-checks 'overlong-summary-line))

(use-package magit
  :general
  (:keymaps 'magit-status-mode-map
   "jl" 'avy-goto-line)

  (my-map
    "g" '(:ignore t :which-key "git")
    "g s" 'magit-status
    "g p" 'magit-dispatch-popup
    "g f" 'magit-file-popup

    ". g" 'my-dots-git)

  :init
  (setq magit-save-repository-buffers 'dontask
        magit-refs-show-commit-count 'all
        magit-log-auto-more t
        magit-diff-refine-hunk t
        magit-display-buffer-function
          #'magit-display-buffer-fullframe-status-v1)

  (defun my-dots-git ()
    "Open a Magit Status buffer for the dotfiles directory."
    (interactive)

    (magit-status-internal my--dots-path))

  (add-hook 'magit-mode-hook #'global-magit-file-mode)

  :config
  (defun my-open-pr ()
    "Visit the current branch's PR on Github."
    (interactive)

    (browse-url
     (format "https://github.com/%s/pull/new/%s"
             (replace-regexp-in-string
              "\\`.+github\\.com:\\(.+\\)\\.git\\'" "\\1"
              (magit-get "remote"
                         (magit-get-push-remote)
                         "url"))
             (magit-get-current-branch))))

  (with-eval-after-load 'magit-ediff
    (add-hook 'magit-ediff-quit-hook #'my--ediff-quit))

  (unless (eq system-type 'windows-nt)
    (magit-wip-after-save-mode)
    (magit-wip-after-apply-mode)
    (magit-wip-before-change-mode)))

(use-package magit-todos
  :defer t
  :straight (:host github :repo "alphapapa/magit-todos")

  :init
  (setq magit-todos-depth -1)

  (add-hook 'magit-status-mode-hook #'magit-todos-mode))

(use-package magithub
  :after magit

  :init
  (setq magithub-dir (my-cache-dir "magithub")
        magithub-api-timeout 5)

  :config
  (magithub-feature-autoinject t))

(use-package vdiff-magit :defer t)

(provide 'conf/git)
