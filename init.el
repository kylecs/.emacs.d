;;; init.el --- my emacs config -*- lexical-binding: t; -*-

;;;; Emacs Config

;;;; Basic Emacs Config
(setq custom-file (expand-file-name "var/custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; Avoid an intermittent macOS NS-port stall while Emacs flushes the built-in
;; startup echo-area message.  Use the runtime login name so this stays
;; portable; `custom-set-variables' supplies the saved-value marker that the
;; specially protected startup option requires.
(custom-set-variables
 (list 'inhibit-startup-echo-area-message (user-login-name)))

(use-package package
  :ensure nil

  :config
  (add-to-list 'package-archives
	       '("melpa" . "https://melpa.org/packages/")))

(use-package emacs
  :ensure nil

  :config
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (tooltip-mode -1)
  (fringe-mode 0)
  (set-face-attribute 'default nil :height 160)
  (global-display-line-numbers-mode 1)
  (keymap-global-unset "<pinch>")
  (electric-pair-mode 1)
  (show-paren-mode 1)
  (minibuffer-depth-indicate-mode 1)

  :custom
  (ns-command-modifier 'meta)
  (ns-option-modifier 'none)
  (use-dialog-box nil)
  (use-file-dialog nil)
  (ring-bell-function #'ignore)
  (visible-bell nil)
  (enable-recursive-minibuffers t)
  (pixel-scroll-precision-mode t)
  (scroll-conservatively 999)
  (show-paren-delay 0))

;; GUI Emacs may not inherit the login shell's PATH on macOS or Linux.  Import
;; it so external tools such as rg and gopls are available to Consult and Eglot.
(use-package exec-path-from-shell
  :ensure t
  :if (or (daemonp) (memq window-system '(mac ns x pgtk)))
  :functions exec-path-from-shell-initialize
  :init
  (exec-path-from-shell-initialize))

(defun kyle/emacs-lisp-flymake-setup ()
  "Enable Flymake without checkdoc diagnostics in Emacs Lisp buffers."
  (remove-hook 'flymake-diagnostic-functions
               #'elisp-flymake-checkdoc
               t)
  (flymake-mode 1))

(add-hook 'emacs-lisp-mode-hook #'kyle/emacs-lisp-flymake-setup)

;; setup persistent state dirs
(let ((backup-dir (expand-file-name "var/backups/" user-emacs-directory))
      (autosave-dir (expand-file-name "var/auto-save/" user-emacs-directory))
      (undo-dir (expand-file-name "var/undo-fu-session/"
                                  user-emacs-directory)))
  (make-directory backup-dir t)
  (make-directory autosave-dir t)
  (make-directory undo-dir t)
  (setopt backup-directory-alist `(("." . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,autosave-dir t))
          undo-fu-session-directory undo-dir))

;;;; Builtin Package Config
(use-package flymake
  :ensure nil

  :custom
  (flymake-show-diagnostics-at-end-of-line 'short)
  (flymake-no-changes-timeout 0.1))

(use-package recentf
  :ensure nil
  :custom
  (recentf-max-saved-items 100)
  :config
  (recentf-mode 1))

(use-package saveplace
  :ensure nil
  :init
  (save-place-mode 1))

(use-package autorevert
  :ensure nil
  :custom
  (global-auto-revert-non-file-buffers t)
  (auto-revert-avoid-polling t)
  :init
  (global-auto-revert-mode 1))

(use-package project
  :ensure nil
  :custom
  ;; After selecting a project, open its root without a second dispatcher.
  (project-switch-commands 'project-dired))

(use-package dired
  :ensure nil
  :after evil
  :defines dired-mode-map
  :functions evil-define-key evil-search-forward evil-search-next evil-search-previous
  :config
  (evil-define-key 'normal dired-mode-map
    (kbd "/") #'evil-search-forward
    (kbd "n") #'evil-search-next
    (kbd "p") #'evil-search-previous))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))

(use-package hideshow
  :ensure nil
  :hook (emacs-lisp-mode . hs-minor-mode))

(use-package tab-bar
  :ensure nil
  :functions tab-bar--current-tab-index tab-bar-select-tab kyle/tab-move-no-wrap
  :defines tab-bar-tabs-function
  :config
  (defun kyle/tab-move-no-wrap (offset)
    "Move OFFSET tabs without wrapping at either end."
    (let* ((tabs (funcall tab-bar-tabs-function))
           (current (tab-bar--current-tab-index tabs))
           (target (+ current offset)))
      (when (<= 0 target (1- (length tabs)))
        (tab-bar-select-tab (1+ target)))))

  (defun kyle/tab-next (&optional arg)
    "Switch forward ARG tabs without wrapping."
    (interactive "p")
    (kyle/tab-move-no-wrap (or arg 1)))

  (defun kyle/tab-previous (&optional arg)
    "Switch backward ARG tabs without wrapping."
    (interactive "p")
    (kyle/tab-move-no-wrap (- (or arg 1)))))

(use-package winner
  :ensure nil
  :init
  (winner-mode 1))

;;;; Visual Packages
(use-package doom-themes
  :ensure t
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t)
  (doom-themes-padded-modeline 4)
  :config
  (load-theme 'doom-acario-light t)
  (set-face-attribute 'tab-bar-tab nil
                      :background (face-background 'mode-line nil t)
                      :foreground (face-foreground 'mode-line nil t)))

(use-package doom-modeline
  :ensure t
  :functions doom-modeline-mode
  :init
  (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 28)
  (doom-modeline-bar-width 3)
  (doom-modeline-icon nil)
  (doom-modeline-major-mode-icon nil)
  (doom-modeline-buffer-state-icon nil)
  (doom-modeline-buffer-file-name-style 'file-name)
  (doom-modeline-modal t)
  (doom-modeline-check 'simple)
  (doom-modeline-minor-modes nil)
  (doom-modeline-buffer-encoding nil))

(use-package dashboard
  :ensure t
  :after activities
  :functions (dashboard-insert-heading dashboard-setup-startup-hook
                                       kyle/dashboard-initialize)
  :defines dashboard-item-generators
  :custom
  (dashboard-startup-banner 'ascii)
  (dashboard-banner-ascii
   (with-temp-buffer
     (insert-file-contents
      (expand-file-name "dashboard-banner.txt" user-emacs-directory))
     (buffer-string)))
  (dashboard-items '((activities . 5)
                     (projects . 5)
                     (recents . 5)))
  (dashboard-projects-backend 'project-el)
  ;; Dashboard entries are destinations; keep project.el's command
  ;; dispatcher on `SPC p p' instead of showing it after a click here.
  (dashboard-projects-switch-function #'dired)
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-set-heading-icons nil)
  (dashboard-set-file-icons nil)
  (dashboard-display-icons-p nil)
  (dashboard-show-shortcuts nil)
  (dashboard-startupify-list
   '(dashboard-insert-banner
     dashboard-insert-newline
     dashboard-insert-items))
  :config
  (defun kyle/dashboard-initialize (&rest _)
    "Show Dashboard without its synchronous startup redisplay.
The forced redisplay can block indefinitely in `ns_flush_display' on macOS."
    (switch-to-buffer dashboard-buffer-name)
    (goto-char (point-min))
    (run-hooks 'dashboard-after-initialize-hook))

  (advice-add 'dashboard-initialize :override #'kyle/dashboard-initialize)
  (add-to-list 'dashboard-item-generators
               '(activities . kyle/dashboard-insert-activities))
  (dashboard-setup-startup-hook))

(use-package which-key
  :ensure t
  :custom
  (which-key-idle-delay 0)
  :config
  (which-key-mode 1))

(use-package avy
  :ensure t
  :commands avy-goto-char-timer)

;;;; Completion Ecosystem Config
(use-package vertico
  :ensure t
  :functions vertico-mode
  :defines vertico-map
  :bind
  (:map vertico-map
        ("C-j" . vertico-next)
        ("C-k" . vertico-previous))
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))

  (completion-category-overrides
   '((file (styles partial-completion)))))

(use-package marginalia
  :ensure t
  :functions marginalia-mode
  :init
  (marginalia-mode 1))

(use-package corfu
  :ensure t
  :functions global-corfu-mode
  :defines corfu-map corfu-continue-commands
  :bind
  (:map corfu-map
        ("C-j" . corfu-next)
        ("C-k" . corfu-previous)
        ("<escape>" . corfu-quit)
        ("TAB" . corfu-complete)
        ("<tab>" . corfu-complete))
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'first)
  :init
  (global-corfu-mode 1)
  :config
  (add-to-list 'corfu-continue-commands
               #'kyle/corfu-next-or-window-down)
  (add-to-list 'corfu-continue-commands
               #'kyle/corfu-previous-or-window-up))

(use-package consult
  :ensure t
  :commands
  (consult-buffer
   consult-flymake
   consult-mark
   consult-recent-file
   consult-line
   consult-ripgrep
   consult-imenu
   consult-xref)
  :init
  (setopt xref-show-xrefs-function #'consult-xref
          xref-show-definitions-function #'consult-xref))

(use-package embark
  :ensure t
  :commands (embark-act embark-dwim embark-bindings)
  :bind
  (("C-." . embark-act)
   ("M-." . embark-dwim)
   ("C-h B" . embark-bindings)))

(use-package embark-consult
  :ensure t
  :after (embark consult)
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package prescient
  :ensure t
  :functions prescient-persist-mode
  :config
  (prescient-persist-mode 1))

(use-package vertico-prescient
  :ensure t
  :after (vertico prescient)
  :functions vertico-prescient-mode
  :custom
  (vertico-prescient-enable-filtering t)
  (vertico-prescient-enable-sorting nil)
  (vertico-prescient-override-sorting nil)

  (vertico-prescient-completion-styles '(orderless basic))
  (vertico-prescient-completion-category-overrides
   '((file (styles partial-completion))))

  :config
  (vertico-prescient-mode 1))

(use-package vertico-multiform
  :ensure nil ;; builtin to vertico
  :after (vertico vertico-prescient)
  :functions vertico-multiform-mode
  :defines vertico-multiform-commands
  :custom
  (vertico-multiform-commands
   '((consult-buffer
      (vertico-sort-override-function
       . prescient-completion-sort))))
  :config
  (vertico-multiform-mode 1))

;;;; Evil btw
(use-package evil
  :ensure t
  :functions
  evil-mode
  :defines evil-undo-system evil-want-C-u-scroll
  :init
  (setq evil-undo-system 'undo-redo)
  (setq evil-want-C-u-scroll t)
  :config
  (evil-mode 1))

(use-package undo-fu-session
  :ensure t
  :functions undo-fu-session-global-mode
  :config
  (undo-fu-session-global-mode 1))

;;;; IDE Config
(use-package treesit
  :ensure nil
  :mode (("\\.go\\'" . go-ts-mode)
         ("\\.\\(?:js\\|mjs\\|cjs\\|jsx\\)\\'" . js-ts-mode)
         ("\\.ts\\'" . typescript-ts-mode)
         ("\\.tsx\\'" . tsx-ts-mode))
  :config
  ;; Install each grammar once with `M-x treesit-install-language-grammar'.
  (dolist (source
           '((go "https://github.com/tree-sitter/tree-sitter-go")
             (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
             (typescript "https://github.com/tree-sitter/tree-sitter-typescript"
                         nil "typescript/src")
             (tsx "https://github.com/tree-sitter/tree-sitter-typescript"
                  nil "tsx/src")))
    (add-to-list 'treesit-language-source-alist source)))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure eglot-rename)
  :hook ((go-ts-mode js-ts-mode typescript-ts-mode tsx-ts-mode)
         . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-initiated-edits nil))

(use-package activities
  :ensure t
  :functions (activities-mode activities-tabs-mode activities-named
                             activities-names activities-resume)
  :custom
  (activities-bookmark-store t)
  :init
  (activities-mode 1)
  (activities-tabs-mode 1))

(defun kyle/dashboard-insert-activities (list-size)
  "Insert up to LIST-SIZE saved activities into the dashboard."
  (dashboard-insert-heading "Activities:")
  (let ((names (seq-take (activities-names) list-size)))
    (if names
        (dolist (name names)
          (insert "\n" (make-string (or standard-indent tab-width 4) ?\s))
          (widget-create
           'item
           :tag name
           :action (lambda (&rest _)
                     (activities-resume (activities-named name)))
           :button-face 'dashboard-items-face
           :mouse-face 'highlight
           :button-prefix ""
           :button-suffix ""
           :format "%[%t%]"))
      (insert (propertize "\n    --- No activities ---"
                          'face 'dashboard-no-items-face)))))

(use-package dirvish
  :ensure t
  :commands dirvish-side
  :functions dirvish-override-dired-mode dirvish-side-follow-mode
  dirvish-side--session-visible-p dirvish-quit
  :defines dirvish-mode-map dirvish-reuse-session

  :preface
  (defun kyle/dirvish-side-toggle ()
    "Toggle the Dirvish sidebar regardless of the selected window."
    (interactive)
    (if-let ((sidebar (dirvish-side--session-visible-p)))
        (let ((origin (selected-window)))
          ;; Keep the index buffer, including its subtree overlays, so the
          ;; next toggle can resume the same sidebar session.
          (let ((dirvish-reuse-session t))
            (with-selected-window sidebar
              (dirvish-quit)))
          (when (window-live-p origin)
            (select-window origin)))
      (dirvish-side)))

  (defun kyle/dirvish-side-disable-line-numbers (buffer)
    "Disable line numbers in Dirvish side BUFFER."
    (with-current-buffer buffer
      (display-line-numbers-mode -1)))

  :init
  (add-to-list 'load-path (concat user-emacs-directory "elpa/dirvish-2.3.0"))
  (add-to-list 'load-path (concat user-emacs-directory "elpa/dirvish-2.3.0/extensions"))
  (require 'dirvish)
  (require 'dirvish-side)
  (require 'dirvish-history)
  (dirvish-override-dired-mode)

  :custom
  ;; Let windmove enter and leave the sidebar like an ordinary window.
  (dirvish-side-window-parameters '((no-delete-other-windows . t)))

  :config
  (advice-add 'dirvish-side-root-conf :after
              #'kyle/dirvish-side-disable-line-numbers)
  (dirvish-side-follow-mode 1))

(use-package ghostel
  :ensure t

  ;; Codex can leave synchronized-output frames stale until the next keypress.
  ;; Use the broadly supported terminal profile so it redraws incrementally.
  :custom
  (ghostel-term "xterm-256color")

  :preface
  (defun kyle/ghostel-new ()
    "Create a new Ghostel terminal instance."
    (interactive)
    (ghostel t))

  (defun kyle/ghostel-project-new ()
    "Create a new Ghostel terminal instance for the current project."
    (interactive)
    (ghostel-project t))

  (defun kyle/ghostel-disable-line-numbers ()
    "Disable line numbers in the current Ghostel buffer."
    (display-line-numbers-mode -1))

  :commands
  (ghostel
   ghostel-other
   ghostel-project
   ghostel-next
   ghostel-previous
   ghostel-list-buffers
   ghostel-project-list-buffers
   ghostel-clear
   ghostel-clear-scrollback)

  :defines ghostel-keymap-exceptions

  :hook
  (ghostel-mode . kyle/ghostel-disable-line-numbers)

  :config
  (setopt ghostel-keymap-exceptions
          (delete-dups
           (append '("C-h" "C-j" "C-k" "C-l")
                   ghostel-keymap-exceptions))))

(use-package evil-ghostel
  :ensure t
  :after (ghostel evil general)
  :functions evil-ghostel-mode general-define-key ghostel-send-key kyle/ghostel-send-escape
  :defines evil-ghostel-mode-map
  :custom
  (evil-ghostel-initial-state 'insert)
  (evil-ghostel-escape 'evil)
  :hook
  (ghostel-mode . evil-ghostel-mode)
  :config
  (defun kyle/ghostel-send-escape ()
    "Send a bare escape key to the terminal."
    (interactive)
    (ghostel-send-key "escape"))

  (general-define-key
   :states '(normal insert visual motion operator replace emacs)
   :keymaps 'evil-ghostel-mode-map
   "C-<escape>" #'kyle/ghostel-send-escape))

;;;; Keybinding Config
(defun kyle/corfu-active-p ()
  "Return non-nil while Corfu is handling an active completion session."
  (and (bound-and-true-p corfu-mode)
       (bound-and-true-p completion-in-region-mode)))

(defun kyle/corfu-next-or-window-down ()
  "Select the next Corfu candidate, or move to the window below."
  (interactive)
  (if (kyle/corfu-active-p)
      (corfu-next)
    (windmove-down)))

(defun kyle/corfu-previous-or-window-up ()
  "Select the previous Corfu candidate, or move to the window above."
  (interactive)
  (if (kyle/corfu-active-p)
      (corfu-previous)
    (windmove-up)))

(use-package general
  :ensure t
  :after evil
  :functions general-define-key general-create-definer kyle/leader
  kyle/tab-previous kyle/tab-next dirvish-subtree-toggle
  dirvish-history-go-backward dirvish-history-go-forward eldoc-doc-buffer
  kyle/corfu-next-or-window-down kyle/corfu-previous-or-window-up
  :defines kyle/leader
  :config
  (general-define-key
   :states '(normal insert visual motion emacs)
   :keymaps 'override
   "C-s" #'save-buffer
   "C-j" #'kyle/corfu-next-or-window-down
   "C-k" #'kyle/corfu-previous-or-window-up
   "C-l" #'windmove-right
   "C-h" #'windmove-left
   "C-." #'embark-act
   "M-." #'embark-dwim
   "S-<right>" #'which-key-show-next-page-cycle
   "S-<left>" #'which-key-show-previous-page-cycle)
  (general-define-key
   :states '(normal visual emacs)
   "H" #'kyle/tab-previous
   "L" #'kyle/tab-next)
  (general-define-key
   :states '(normal visual)
   "gc" #'comment-line)
  (general-define-key
   :states 'normal
   "K" #'eldoc-doc-buffer)
  (general-define-key
   :keymaps 'which-key-C-h-map
   "<right>" #'which-key-show-next-page-cycle
   "<left>" #'which-key-show-previous-page-cycle)
  (general-define-key
   :states 'normal
   :keymaps 'dirvish-mode-map
   "<tab>" #'dirvish-subtree-toggle
   "H" #'kyle/tab-previous
   "L" #'kyle/tab-next
   "M-h" #'dirvish-history-go-backward
   "M-l" #'dirvish-history-go-forward)
  (general-create-definer kyle/leader
			  :states '(normal visual insert motion emacs)
			  :keymaps 'override
			  :prefix "SPC"
			  :non-normal-prefix "C-c SPC")
  (kyle/leader
    ;; Top-level Emacs commands.
    ":" '(execute-extended-command :which-key "M-x")
    "." '(find-file :which-key "find file")
    "," '(consult-buffer :which-key "switch buffer")
    "?" '(which-key-show-top-level :which-key "show active keybindings")
    "j" '(avy-goto-char-timer :which-key "jump to visible text")
    "u" '(universal-argument :which-key "universal argument")

    ;; Code navigation and editing.
    "c"   '(:ignore t :which-key "code")
    "c r" '(eglot-rename :which-key "rename symbol")
    "c f" '(xref-find-references :which-key "find references")

    ;; Files.
    "f"   '(:ignore t :which-key "files")
    "f f" '(find-file :which-key "find file")
    "f s" '(save-buffer :which-key "save file")
    "f S" '(save-some-buffers :which-key "save all files")
    "f d" '(dired :which-key "open directory")
    "f r" '(consult-recent-file :which-key "recent files")
    "f R" '(rename-visited-file :which-key "rename file")

    ;; Buffers.
    "b"   '(:ignore t :which-key "buffers")
    "b b" '(consult-buffer :which-key "switch buffer")
    "b l" '(list-buffers :which-key "list buffers")
    "b d" '(kill-current-buffer :which-key "delete(kill) buffer")
    "b n" '(next-buffer :which-key "next buffer")
    "b p" '(previous-buffer :which-key "previous buffer")
    "b r" '(rename-buffer :which-key "rename buffer")
    "b R" '(revert-buffer :which-key "revert buffer")

    ;; Activities.
    "a"   '(:ignore t :which-key "activities")
    "a n" '(activities-new :which-key "new activity")
    "a d" '(activities-define :which-key "define activity")
    "a a" '(activities-resume :which-key "select activity")
    "a s" '(activities-suspend :which-key "suspend activity")
    "a b" '(activities-switch-buffer :which-key "activity buffer")
    "a g" '(activities-revert :which-key "revert activity")
    "a k" '(activities-kill :which-key "kill activity")
    "a x" '(activities-discard :which-key "discard activity")
    "a l" '(activities-list :which-key "list activities")

    ;; Projects.
    "p"   '(:ignore t :which-key "projects")
    "p p" '(project-switch-project :which-key "switch project")
    "p a" '(project-remember-projects-under :which-key "add projects")
    "p f" '(project-find-file :which-key "find file")
    "p d" '(project-dired :which-key "project directory")
    "p b" '(project-switch-to-buffer :which-key "switch buffer")
    "p s" '(project-find-regexp :which-key "search project")
    "p r" '(project-query-replace-regexp :which-key "replace in project")
    "p c" '(project-compile :which-key "compile project")
    "p t" '(ghostel-project :which-key "project terminal")
    "p v" '(project-vc-dir :which-key "version control")
    "p k" '(project-kill-buffers :which-key "kill project buffers")
    "p x" '(project-forget-project :which-key "forget project")

    ;; Windows.
    "w"   '(:ignore t :which-key "windows")
    "w t" '(tab-new :which-key "new tab")
    "w h" '(windmove-left :which-key "window left")
    "w j" '(windmove-down :which-key "window down")
    "w k" '(windmove-up :which-key "window up")
    "w l" '(windmove-right :which-key "window right")
    "w v" '(split-window-right :which-key "split right")
    "w s" '(split-window-below :which-key "split below")
    "w d" '(delete-window :which-key "delete window")
    "w o" '(delete-other-windows :which-key "delete other windows")
    "w w" '(other-window :which-key "next window")
    "w r" '(evil-window-rotate-downwards :which-key "rotate windows counter clockwise")
    "w R" '(evil-window-rotate-upwards :which-key "rotate windows clockwise")
    "w u" '(winner-undo :which-key "undo window layout")
    "w U" '(winner-redo :which-key "redo window layout")
    "w =" '(balance-windows :which-key "balance windows")
    "w z" '(maximize-window :which-key "maximize window")

    ;; Search
    "s"   '(:ignore t :which-key "search")
    "s l" '(consult-line :which-key "search lines")
    "s g" '(consult-ripgrep :which-key "search project")
    "s i" '(consult-imenu :which-key "buffer symbols")
    "s d" '(consult-flymake :which-key "diagnostics")
    "s m" '(consult-mark :which-key "marks")

    ;; Sidebar.
    "e" '(kyle/dirvish-side-toggle :which-key "toggle project tree")

    ;; Terminals.
    "t"   '(:ignore t :which-key "terminal")

    ;; Reuse an existing terminal, or create one when none exists.
    "t t" '(ghostel-other :which-key "open terminal")

    ;; Explicitly create new terminals.
    "t n" '(kyle/ghostel-new :which-key "new terminal")
    "t p" '(kyle/ghostel-project-new :which-key "new project terminal")

    ;; Select from existing terminals.
    "t b" '(ghostel-list-buffers :which-key "terminal buffers")
    "t B" '(ghostel-project-list-buffers
	    :which-key "project terminal buffers")

    ;; Cycle through terminals.
    "t ]" '(ghostel-next :which-key "next terminal")
    "t [" '(ghostel-previous :which-key "previous terminal")

    ;; Clear the current terminal.
    "t c" '(ghostel-clear :which-key "clear screen")
    "t C" '(ghostel-clear-scrollback :which-key "clear scrollback")

    ;; Help.
    "h"   '(:ignore t :which-key "help")
    "h k" '(describe-key :which-key "describe key")
    "h f" '(describe-function :which-key "describe function")
    "h v" '(describe-variable :which-key "describe variable")
    "h m" '(describe-mode :which-key "describe mode")
    "h b" '(describe-bindings :which-key "describe bindings")
    "h c" '(describe-char :which-key "describe character")
    "h o" '(describe-symbol :which-key "describe symbol")
    "h i" '(info :which-key "open Info manuals")

    "q" '(:ignore t :which-key "quit emacs")
    "q q" '(evil-quit-all :which-key "confirm quit emacs")))
