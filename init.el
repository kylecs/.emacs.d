;;; init.el --- my emacs config -*- lexical-binding: t; -*-

;;;; Emacs Config

;;;; Basic Emacs Config
(setopt use-package-always-ensure t)

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
  (add-to-list 'default-frame-alist '(left-fringe . 0))
  (add-to-list 'default-frame-alist '(right-fringe . 0))
  (fringe-mode 0)
  (set-face-attribute 'default nil :height 160)
  (global-display-line-numbers-mode 1)
  (keymap-global-unset "<pinch>")
  (global-completion-preview-mode 1)
  (electric-pair-mode 1)
  (show-paren-mode 1)

  :custom
  (ns-command-modifier 'meta)
  (ns-option-modifier 'none)
  (use-dialog-box nil)
  (use-file-dialog nil)
  (ring-bell-function #'ignore)
  (visible-bell nil)
  (pixel-scroll-precision-mode t)
  (scroll-conservatively 999)
  (show-paren-delay 0))

;; remove checkdoc diagnostics from elisp
(add-hook 'emacs-lisp-mode-hook
	  (lambda ()
	    (remove-hook 'flymake-diagnostic-functions
			 #'elisp-flymake-checkdoc
			 t)
	    (flymake-mode 1)))

;; setup backup dirs
(let ((backup-dir (expand-file-name "var/backups/" user-emacs-directory))
      (autosave-dir (expand-file-name "var/auto-save/" user-emacs-directory)))
  (make-directory backup-dir t)
  (make-directory autosave-dir t)
  (setopt backup-directory-alist `(("." . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,autosave-dir t))))

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
  :functions tab-bar--current-tab-index tab-bar-select-tab
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
  :functions (dashboard-insert-heading dashboard-setup-startup-hook)
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
  (add-to-list 'dashboard-item-generators
               '(activities . kyle/dashboard-insert-activities))
  (dashboard-setup-startup-hook))

(use-package which-key
  :ensure t
  :custom
  (which-key-idle-delay 0)
  :config
  (which-key-mode 1))

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

;;;; IDE Config
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

(use-package treemacs
  :ensure t
  :commands
  (treemacs
   treemacs-find-file
   treemacs-add-and-display-current-project)

  :functions treemacs-follow-mode treemacs-filewatch-mode

  :hook
  (treemacs-mode . (lambda ()
                     (display-line-numbers-mode -1)
                     ;; Keep an empty mode line as an active-window indicator.
                     (setq-local mode-line-format '(" "))))

  :custom
  (treemacs-width 32)

  (treemacs-show-hidden-files t)

  ;; Use Treemacs's plain text fallbacks instead of graphical file icons.
  (treemacs-no-png-images t)

  :config
  (treemacs-follow-mode 1)

  (treemacs-filewatch-mode 1))

(use-package treemacs-evil
  :ensure t
  :after (treemacs evil))

(use-package ghostel
  :ensure t

  :preface
  (defun kyle/ghostel-new ()
    "Create a new Ghostel terminal instance."
    (interactive)
    (ghostel t))

  (defun kyle/ghostel-project-new ()
    "Create a new Ghostel terminal instance for the current project."
    (interactive)
    (ghostel-project t))

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
  (ghostel-mode . (lambda ()
		    (display-line-numbers-mode -1)
                    ;; Precision scrolling can overshoot the live terminal's
                    ;; bottom edge and fight Ghostel's viewport anchoring.
                    (setq-local pixel-scroll-precision-mode nil)))

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
(use-package general
  :ensure t
  :after evil
  :functions general-define-key general-create-definer kyle/leader
  :defines kyle/leader
  :config
  (general-define-key
   :states '(normal insert visual motion emacs)
   :keymaps 'override
   "C-s" #'save-buffer
   "C-j" #'windmove-down
   "C-k" #'windmove-up
   "C-l" #'windmove-right
   "C-h" #'windmove-left)
  (general-define-key
   :states '(normal visual emacs)
   "H" #'kyle/tab-previous
   "L" #'kyle/tab-next)
  (general-define-key
   :states '(normal visual)
   "gc" #'comment-line)
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
    "u" '(universal-argument :which-key "universal argument")

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
    "a r" '(activities-resume :which-key "resume activity")
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
    "w =" '(balance-windows :which-key "balance windows")
    "w z" '(maximize-window :which-key "maximize window")

    ;; Search
    "s"   '(:ignore t :which-key "search")
    "s l" '(consult-line :which-key "search lines")
    "s g" '(consult-ripgrep :which-key "search project")
    "s i" '(consult-imenu :which-key "buffer symbols")
    "s d" '(consult-flymake :which-key "diagnostics")
    "s m" '(consult-mark :which-key "marks")

    ;; Sidebar
    "e" '(treemacs :which-key "toggle project tree")
    "E"   '(:ignore t :which-key "project tree")
    "E f" '(treemacs-find-file :which-key "find current file")
    "E a" '(treemacs-add-and-display-current-project
	    :which-key "add current project")

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
    "h r" '((lambda ()
               (interactive)
               (load-file user-init-file))
             :which-key "reload config")

    "q" '(:ignore t :which-key "quit emacs")
    "q q" '(evil-quit-all :which-key "confirm quit emacs")))

;;;; Autogenerated
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
