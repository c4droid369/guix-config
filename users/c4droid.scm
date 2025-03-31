(define-module (users c4droid)
  #:use-module (guix gexp)
  #:use-module (guix utils)

  #:use-module (gnu home)

  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services shells)

  #:use-module (gnu packages)

  #:use-module (gnu services shepherd)

  #:use-module (packages emacs-xyz))

;; Dotfile directory
(define dotfiles
  (string-append (current-source-directory) "/../dotfiles"))

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

(home-environment
 (packages
  (append %networking
          %editor
          %emacs-plugin
          %develop
          %utility))
 (services (append (list (service home-bash-service-type
                                  (home-bash-configuration
                                   (bashrc (list (local-file (string-append dotfiles "/bashrc"))))
                                   (bash-profile (list (local-file (string-append dotfiles "/bash_profile"))))))
                         (service home-shepherd-service-type
                                  (home-shepherd-configuration
                                   (services (list (shepherd-service
                                                    (provision '(emacs-daemon))
                                                    (documentation "Emacs daemon")
                                                    (start #~(make-forkexec-constructor '("emacs" "--fg-daemon")))
                                                    (stop #~(make-kill-destructor))))))))
                   %base-home-services)))
