(define-module (users c4droid)
  #:use-module (guix gexp)
  #:use-module (guix utils)

  #:use-module (gnu home)

  #:use-module (gnu home services)
  #:use-module (gnu home services dotfiles)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services gnupg)

  #:use-module (gnu packages)
  #:use-module (gnu packages gnupg)

  #:use-module (gnu services)
  #:use-module (gnu services shepherd)

  #:use-module (c4droid packages emacs-xyz))

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
         "emacs-diminish"
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
         "emacs-rainbow-delimiters"
         "emacs-vertico"
         "emacs-consult"
         "emacs-consult-dir"
         "emacs-marginalia"
         "emacs-embark"
         "emacs-orderless"
         "emacs-magit"
         "emacs-corfu"
         "emacs-cape"
         "emacs-pinentry")))

(define %develop
  (map specification->package+output
       '("git")))

(define %utility
  (map specification->package+output
       '("ncurses" "tmux" "ripgrep" "fd")))

(define %secrets
  (map specification->package+output
       '("gnupg"
         "pinentry-emacs")))

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
          %utility
          %secrets))
 (services (append (list (simple-service 'env-vars-services
                                         home-environment-variables-service-type
                                         `(("EDITOR" . "emacsclient -t")
                                           ("VISUAL" . "emacsclient -t")))
                         (service home-shepherd-service-type
                                  (home-shepherd-configuration
                                   (services (list %emacs-daemon))))
                         (service home-dotfiles-service-type
                                  (home-dotfiles-configuration
                                   (directories `(,(string-append (current-source-directory) "/../dotfiles")))
                                   (excluded '("\\.git" "README.md" "LICENSE"))))
                         (service home-gpg-agent-service-type
                                  (home-gpg-agent-configuration
                                   (pinentry-program (file-append pinentry-emacs "/bin/pinentry-emacs"))
                                   (ssh-support? #t)
                                   (default-cache-ttl 86400)
                                   (max-cache-ttl 86400))))
                   %base-home-services)))
