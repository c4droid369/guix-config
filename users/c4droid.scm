(define-module (users c4droid)
  #:use-module (guix gexp)
  #:use-module (guix utils)

  #:use-module (gnu home)

  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services shells)

  #:use-module (gnu packages)

  #:use-module (gnu services)
  #:use-module (gnu services shepherd)

  #:use-module (packages emacs-xyz))

;; Package category
(define %networking
  (map specification->package+output
       '("curl" "wget")))

(define %editor
  (map specification->package+output
       '("emacs-no-x")))

(define %emacs-plugin
  (map specification->package+output
       '("emacs-setup"
         "emacs-guix"
         "emacs-evil"
         "emacs-evil-collection"
         "emacs-evil-surround"
         "emacs-evil-commentary"
         "emacs-evil-easymotion"
         "emacs-evil-escape"
         "emacs-evil-god-state"
         "emacs-evil-vimish-fold"
         "emacs-evil-matchit"
         "emacs-evil-args"
         "emacs-evil-indent-plus"
         "emacs-god-mode"
         "emacs-vimish-fold"
         "emacs-lispy"
         "emacs-lispyville"
         "emacs-rainbow-delimiters")))

(define %develop
  (map specification->package+output
       '("git")))

(define %utility
  (map specification->package+output
       '("ncurses" "tmux")))

;; Home services
(define %emacs-daemon
  (shepherd-service
   (provision '(emacs-daemon))
   (documentation "Emacs daemon")
   (start #~(make-forkexec-constructor '("emacs" "--fg-daemon")))
   (stop #~(make-kill-destructor))))

(home-environment
 (packages
  (append %networking
          %editor
          %emacs-plugin
          %develop
          %utility))
 (services (append (list (service home-bash-service-type)
                         (simple-service 'env-vars-services
                                         home-environment-variables-service-type
                                         `(("EDITOR" . "emacsclient -t")
                                           ("VISUAL" . "emacsclient -t")))
                         (service home-shepherd-service-type
                                  (home-shepherd-configuration
                                   (services (list %emacs-daemon))))
                         (service home-dotfiles-service-type
                                  (home-dotfiles-configuration
                                   (layout 'stow)
                                   (directories `(,(string-append (current-source-directory) "/../dotfiles"))))))
                   %base-home-services)))
