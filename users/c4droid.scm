(define-module (users c4droid)
  ;; Guix scheme library
  #:use-module (guix gexp)
  #:use-module (guix utils)
  ;; Guix home library
  #:use-module (gnu home)
  ;; Guix home services
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services shells)
  ;; Guix packages
  #:use-module (gnu packages)
  ;; Guix services
  #:use-module (gnu services shepherd))

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
       '("emacs-guix")))

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
                                                    (provision '(emacs-server))
                                                    (documentation "Emacs server")
                                                    (start #~(make-forkexec-constructor '("emacs" "--fg-daemon")))
                                                    (stop #~(make-kill-destructor))))))))
                   %base-home-services)))
