
;; some basic qol things
(setopt load-prefer-newer t)
(setopt inhibit-startup-message t)
(setopt visible-bell t)
(scroll-bar-mode -1)
(tooltip-mode -1)
(tool-bar-mode -1)
(set-fringe-mode 10)
;; (menu-bar-mode -1) breaks fullscreen
(global-display-line-numbers-mode)
(setopt display-line-numbers-width 3)
(setopt which-key-idle-delay 0.0)
(which-key-mode 1)
(pixel-scroll-precision-mode 1)

;; save my fingers
(setopt mac-option-modifier 'super)
(setopt mac-command-modifier 'meta)

(set-face-attribute 'default nil :font "GeistMono Nerd Font" :height 200)

;; ESC should escape prompts immediately
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; package setup
(require 'package)
(setopt package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setopt use-package-always-ensure t)

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

(use-package diminish)
(require 'diminish)

(diminish 'which-key-mode)

;; theme setup
(use-package doom-themes
  :custom
  ;; Global settings (defaults)
  (doom-themes-enable-bold t)   ; if nil, bold is universally disabled
  (doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; for treemacs users
  ;;(doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  :config
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (nerd-icons must be installed!)
  ;;(doom-themes-neotree-config)
  ;; or for treemacs users
  ;;(doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;; stop asking me about this pls
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("4130a9efe19a6a298ebb86a09652511ffed35c4fd611ad3028b47dcea1f756f4"
     default))
 '(package-selected-packages
   '(all-the-icons counsel dashboard diminish doom-modeline doom-themes
		   evil evil-leader exec-path-from-shell lsp-mode
		   tree-sitter-langs treesit-auto))
 '(warning-suppress-types '((files missing-lexbind-cookie "~/.emacs.d/init.el"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; load up manually downloaded rose pine dawn theme
(load "~/.emacs.d/doom-rose-pine-dawn-theme.el")
(load-theme 'doom-rose-pine-dawn)

;; fix fringe color
(set-face-attribute 'fringe nil :background nil)

;; vim mode setup
(use-package evil-leader)
(require 'evil-leader)


(use-package evil)
(require 'evil)
(evil-mode 1)


(use-package ivy
  :diminish
  :config
  (ivy-mode 1))

(use-package counsel
  :diminish
  :config
  (counsel-mode 1))

(use-package doom-modeline
  :init (doom-modeline-mode 1))

(use-package nerd-icons)

(use-package dashboard
  :config
  (dashboard-setup-startup-hook))

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook (
         (go-mod-ts-mode . lsp)
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

