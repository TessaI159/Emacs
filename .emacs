(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
	     '("org" . "https://orgmode.org/elpa/") t)
(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

(setq package-selected-packages '(rainbow-delimiters rainbow-mode which-key
						     helm-swoop use-package zone-rainbow
						     flycheck helm-file-preview helm-flycheck
						     crux ace-window dashboard projectile
						     python-mode helm-projectile))

(when (cl-find-if-not #'package-installed-p package-selected-packages)
  (package-refresh-contents)
  (mapc #'package-install package-selected-packages))


(eval-when-compile (require 'use-package))
(require 'use-package-ensure)
(setq use-package-always-ensure t)


(setq inhibit-startup-message t)
(setq inhibit-splash-screen t)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

(load-theme 'plan9 t)

(use-package ace-window
  :bind
  ("C-c o" . ace-window)
  ("C-c w" . ace-swap-window)
  :init
  (setq aw-keys '(?a ?s ?d ?f ?j ?k ?l)))


(global-unset-key (kbd "C-z"))
(global-unset-key (kbd "C-x C-z"))
(global-unset-key (kbd "M-c"))

(global-set-key (kbd "C-x f") 'helm-find-files)

(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-banner-logo-title "Welcome back, Tess")
  (setq dashboard-startup-banner 'official)
  (setq dashboard-center-content t)
  (setq dashboard-items '((recents . 10)
			  (projects . 5)))
  (setq dashboard-set-navigator t)
  (setq dashboard-set-init-info t)
  (setq dashboard-set-footer nil))

(use-package flycheck
  :hook
  (c++-mode . flycheck-mode)
  (c++-mode . (lambda ()
		(setq flycheck-clang-language-standard="c++17")))
  (c++-mode . (lambda ()
		(setq flycheck-clang-include-path (list (expand-file-name "/usr/local/include/opencv4"))))))


(which-key-mode)
(setq which-key-max-description-length 60)

(defun ti/display-line-numbers-on-hook ()
  (display-line-numbers-mode t))

(add-hook 'prog-mode-hook 'ti/display-line-numbers-on-hook)

(use-package crux
  :bind
  ("C-c d" . crux-duplicate-current-line-or-region)
  ("C-c t" . crux-visit-term-buffer)
  ("C-c ," . crux-find-user-init-file)
  ([remap open-line] . crux-smart-open-line)
  ([remap move-beginning-of-line] . crux-move-beginning-of-line))

(use-package emacs
  :init
  ;; Auto-close parens
  (electric-pair-mode +1)
  ;; Disable for <
  (add-function :before-until electric-pair-inhibit-predicate
		(lambda (c) (eq c ?<))))

(global-hl-line-mode 1)
(set-face-background 'hl-line "PaleTurquoise")
(setq shift-select-mode nil)

(setq fixme-modes '(c++-mode c-mode emacs-lisp-mode))
(make-face 'font-lock-fixme-face)
(make-face 'font-lock-study-face)
(make-face 'font-lock-important-face)
(make-face 'font-lock-note-face)
(mapc (lambda (mode)
	(font-lock-add-keywords
	 mode
	 '(("\\<\\(TODO\\)" 1 'font-lock-fixme-face t)
	   ("\\<\\(STUDY\\)" 1 'font-lock-study-face t)
	   ("\\<\\(IMPORTANT\\)" 1 'font-lock-important-face t)
	   ("\\<\\(NOTE\\)" 1 'font-lock-note-face t))))
      fixme-modes)
(modify-face 'font-lock-fixme-face "DeepPink1" nil nil t nil t nil nil)
(modify-face 'font-lock-study-face "Salmon" nil nil t nil t nil nil)
(modify-face 'font-lock-important-face "Salmon" nil nil t nil t nil nil)
(modify-face 'font-lock-note-face "Red" nil nil t nil t nil nil)

(global-auto-revert-mode t)
(fset 'yes-or-no-p 'y-or-n-p)

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-mode))

(projectile-mode +1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

(setq projectile-project-search-path '("w:\handmade\code" "v:\VHS2"))



(require 'helm)
(helm-mode)

(setq helm-split-window-in-side-p t)

(setq helm-swoop-split-with-multiple-windows nil
      helm-swoop-split-direction 'split-window-vertically
      helm-swoop-split-window-function 'helm-default-display-buffer)

(setq helm-echo-input-in-header-line t)

(defvar bottom-buffers nil
  "List of bottom buffers before helm session.
    Its element is a pair of `buffer-name' and `mode-line-format'.")

(defun bottom-buffers-init ()
  (setq-local mode-line-format (default-value 'mode-line-format))
  (setq bottom-buffers
	(cl-loop for w in (window-list)
		 when (window-at-side-p w 'bottom)
		 collect (with-current-buffer (window-buffer w)
			   (cons (buffer-name) mode-line-format)))))


(defun bottom-buffers-hide-mode-line ()
  (setq-default cursor-in-non-selected-windows nil)
  (mapc (lambda (elt)
	  (with-current-buffer (car elt)
	    (setq-local mode-line-format nil)))
	bottom-buffers))


(defun bottom-buffers-show-mode-line ()
  (setq-default cursor-in-non-selected-windows t)
  (when bottom-buffers
    (mapc (lambda (elt)
	    (with-current-buffer (car elt)
	      (setq-local mode-line-format (cdr elt))))
	  bottom-buffers)
    (setq bottom-buffers nil)))

(defun helm-keyboard-quit-advice (orig-func &rest args)
  (bottom-buffers-show-mode-line)
  (apply orig-func args))


(add-hook 'helm-before-initialize-hook #'bottom-buffers-init)
(add-hook 'helm-after-initialize-hook #'bottom-buffers-hide-mode-line)
(add-hook 'helm-exit-minibuffer-hook #'bottom-buffers-show-mode-line)
(add-hook 'helm-cleanup-hook #'bottom-buffers-show-mode-line)
(advice-add 'helm-keyboard-quit :around #'helm-keyboard-quit-advice)

(defun helm-hide-minibuffer-maybe ()
  (when (with-helm-buffer helm-echo-input-in-header-line)
    (let ((ov (make-overlay (point-min) (point-max) nil nil t)))
      (overlay-put ov 'window (selected-window))
      (overlay-put ov 'face (let ((bg-color (face-background 'default nil)))
			      `(:background ,bg-color :foreground ,bg-color)))
      (setq-local cursor-type nil))))
(add-hook 'helm-minibuffer-set-up-hook 'helm-hide-minibuffer-maybe)


(define-key global-map [remap find-file] #'helm-find-files)
(define-key global-map [remap execute-extended-command] #'helm-M-x)
(define-key global-map [remap switch-to-buffer] #'helm-mini)
(define-key global-map [remap list-buffers] #'helm-mini)


(global-set-key (kbd "M-y") 'helm-show-kill-ring)
(global-set-key (kbd "C-c h o") 'helm-swoop)
(global-set-key (kbd "C-c s") 'helm-multi-swoop-all)
(global-set-key (kbd "C-c r") 'helm-recentf)
(global-set-key (kbd "C-c C-h SPC") 'helm-all-mark-rings)
(global-set-key (kbd "C-c h g") 'helm-google-suggest)
(setq helm-swoop-split-direction 'split-window-vertically)

(defun ti/scroll-up-1 ()
  "Scroll up by one line."
  (interactive)
  (cua-mode)
  (cua-scroll-up 1)
  (cua-mode))

(defun ti/scroll-down-1 ()
  "Scroll down by one line."
  (interactive)
  (cua-mode)
  (cua-scroll-down 1)
  (cua-mode))

(global-set-key (kbd "M-p") 'ti/scroll-down-1)
(global-set-key (kbd "M-n") 'ti/scroll-up-1)

(defun ti/kill-this-buffer ()
  "Kill the current buffer"
  (interactive)
  (kill-buffer (current-buffer)))


(global-set-key (kbd "C-x C-k") 'ti/kill-this-buffer)

(defun ti/rename-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
	(filename (buffer-file-name)))
    (if (not filename)
	(message "Buffer '%s' is not visiting a file!" name)
      (if (get-buffer new-name)
	  (message "A buffer named '%s' already exists!" new-name)
	(progn
	  (rename-file name new-name 1)
	  (rename-buffer new-name)
	  (set-visited-file-name new-name)
	  (set-buffer-modified-p nil))))))

(defun ti/increment-number-at-point ()
  (interactive)
  (skip-chars-backward "-0123456789")
  (or (looking-at "[-0123456789]+")
      (error "No number at point"))
  (replace-match (number-to-string (1+ (string-to-number (match-string 0))))))

(defun ti/decrement-number-at-point ()
  (interactive)
  (skip-chars-backward "-0123456789")
  (or (looking-at "[-0123456789]+")
      (error "No number at point"))
  (replace-match (number-to-string (1- (string-to-number (match-string 0))))))


(global-set-key (kbd "C-c f b") 'ti/rename-file-and-buffer)
(global-set-key (kbd "C-c i") 'ti/increment-number-at-point)
(global-set-key (kbd "C-c u") 'ti/decrement-number-at-point)

(defun ti/indent-buffer ()
  (interactive)
  (push-mark)
  (mark-whole-buffer)
  (crux-cleanup-buffer-or-region)
  (execute-kbd-macro (kbd "C-u C-SPC"))
  (execute-kbd-macro (kbd "C-u C-SPC")))

(global-set-key (kbd "C-c n") 'ti/indent-buffer)

(defun ti/insert-pretty-equation ()
  (interactive)
  (insert "\\textbf{FORMULA } for the #\n")
  (insert "\\begin{displaymath}\n\n")
  (insert "\\end{displaymath}")
  (backward-char 50))


(global-set-key (kbd "C-c C-u") 'ti/insert-pretty-equation)

(defun ti/insert-todo ()
  (interactive)
  (insert "// TODO (Tess): "))

(global-set-key (kbd "C-c v t") 'ti/insert-todo)

(defun ti/insert-note ()
  (interactive)
  (insert "// NOTE (Tess): "))

(global-set-key (kbd "C-c v n") 'ti/insert-note)

(setq gdb-many-windows t)

(setq gdb-show-main t)

(setq history-delete-duplicates t)

(setq bookmark-save-flag t)

(setq scroll-step 1 scroll-conservatively 10000)
(setq scroll-margin 0)
(setq use-package-compute-statistics t)

(setq global-mark-ring-max 2500)
(setq mark-ring-max 2500)
(setq kill-ring-max 150)

(setq require-final-newline nil)

(setq make-backup-files nil)
(setq auto-save-default nil)

(setq initial-scratch-message nil)

(require 'paren)
(require 'rainbow-delimiters)
(show-paren-mode 1)
(setq show-paren-delay 0)

(defun ti/rainbow-stuff ()
  "Used to turn on various rainbow-y packages like rainbow-delimiters
zone-rainbow and rainbow-mode"
  (rainbow-delimiters-mode)
  (rainbow-mode))

(add-hook 'prog-mode-hook 'ti/rainbow-stuff)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(helm-completion-style 'helm)
 '(nil nil t)
 '(org-agenda-files '("~/org/Books.org" "~/org/Tasks.org" "~/org/Blog.org"))
 '(package-selected-packages
   '(leuven-theme plan9-theme rainbow-delimiters rainbow-mode which-key helm-swoop use-package zone-rainbow flycheck helm-file-preview helm-flycheck ace-window dashboard python-mode helm-projectile))
 '(show-paren-mode t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(rainbow-delimiters-base-error-face ((t nil))))
