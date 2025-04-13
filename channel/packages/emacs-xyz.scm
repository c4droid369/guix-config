(define-module (packages emacs-xyz)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-xyz))

(define-public emacs-evil-god-state
  (let ((commit "3d44197dc0a1fb40e7b7ff8717f8a8c339ce1d40")
        (revision "0"))
    (package
      (name "emacs-evil-god-state")
      (version (git-version "0.1" revision commit))
      (source
       (origin
         (uri (git-reference
               (url "https://github.com/gridaphobe/evil-god-state")
               (commit commit)))
         (method git-fetch)
         (sha256
          (base32 "1cv24qnxxf6n1grf4n5969v8y9xll5zb9mbfdnq9iavdvhnndk2h"))
         (file-name (git-file-name name version))))
      (build-system emacs-build-system)
      (propagated-inputs `(("emacs-evil" ,emacs-evil)
                           ("emacs-god-mode" ,emacs-god-mode)))
      (home-page "https://github.com/gridaphobe/evil-god-state")
      (synopsis "Evil mode state for using god-mode")
      (description "evil-god-state is a evil state for the god-mode.
It allow user can be use god-mode with evil-mode.")
      (license license:gpl2))))

(define-public emacs-evil-easymotion
  (let ((commit "f96c2ed38ddc07908db7c3c11bcd6285a3e8c2e9")
        (revision "0"))
    (package
      (name "emacs-evil-easymotion")
      (version (git-version "0.1" revision commit))
      (source
       (origin
         (uri (git-reference
               (url "https://github.com/PythonNut/evil-easymotion")
               (commit commit)))
         (method git-fetch)
         (sha256
          (base32 "0xsva9bnlfwfmccm38qh3yvn4jr9za5rxqn4pwxbmhnx4rk47cch"))
         (file-name (git-file-name name version))))
      (build-system emacs-build-system)
      (propagated-inputs `(("emacs-evil" ,emacs-evil)
                           ("emacs-avy" ,emacs-avy)))
      (home-page "https://github.com/PythonNut/evil-easymotion")
      (synopsis "Emacs port for vim-easymotion")
      (description "evil-easymotion is Emacs port for vim-easymotion.")
      (license license:gpl2))))

(define-public emacs-vimish-fold
  (let ((commit "a6501cbfe3db791f9ca17fd986c7202a87f3adb8")
        (revision "0"))
    (package
      (name "emacs-vimish-fold")
      (version (git-version "0.1" revision commit))
      (source
       (origin
         (uri (git-reference
               (url "https://github.com/matsievskiysv/vimish-fold")
               (commit commit)))
         (method git-fetch)
         (sha256
          (base32 "0w0r951c6vn890h1cz5l8rl6hicna6rbdzfgbg4lpm280yds9lpb"))
         (file-name (git-file-name name version))))
      (build-system emacs-build-system)
      (propagated-inputs `(("emacs-f" ,emacs-f)))
      (home-page "https://github.com/matsievskiysv/vimish-fold")
      (synopsis "Integration of vimish-fold with evil")
      (description
       "Add standard vim keybindings to create and delete folds respectively.")
      (license license:gpl2))))

(define-public emacs-evil-vimish-fold
  (let ((commit "b6e0e6b91b8cd047e80debef1a536d9d49eef31a")
        (revision "0"))
    (package
      (name "emacs-evil-vimish-fold")
      (version (git-version "0.1" revision commit))
      (source
       (origin
         (uri (git-reference
               (url "https://github.com/alexmurray/evil-vimish-fold")
               (commit commit)))
         (method git-fetch)
         (sha256
          (base32 "14qhfhk3d4c7v4jhr909dbxy8222flpqwk73bwg0pqwpkcifyv7n"))
         (file-name (git-file-name name version))))
      (build-system emacs-build-system)
      (propagated-inputs `(("emacs-evil" ,emacs-evil)
                           ("emacs-vimish-fold" ,emacs-vimish-fold)))
      (home-page "https://github.com/alexmurray/evil-vimish-fold")
      (synopsis "Integration of vimish-fold with evil")
      (description
       "Add standard vim keybindings to create and delete folds respectively.")
      (license license:gpl2))))
