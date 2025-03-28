(define-module (services fhs)
  ;; Scheme library
  #:use-module (ice-9 ftw)
  #:use-module (srfi srfi-1)
  ;; Guix Scheme library
  #:use-module (guix records)
  #:use-module (guix gexp)
  ;; Guix utility
  #:use-module (guix profiles)
  #:use-module (guix packages)
  ;; Guix packages
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  ;; Guix services
  #:use-module (gnu services)
  ;; Module exports
  #:export (fhs-binaries-compatibility-service-type
            fhs-configuration))

(define (32bit-package pkg)
  (package
    (inherit pkg)
    (name (string-append (package-name pkg) "-i686-linux"))
    (arguments
     `(#:system "i686-linux" ,@(package-arguments pkg)))))

(define glibc-for-fhs
  (package
    (inherit glibc)
    (name "glibc-for-fhs")
    (source (origin
              (inherit (package-source glibc))
              (snippet #f)))))

(define (packages->ld.so.conf packages)
  (computed-file "ld.so.conf" (with-imported-modules `((guix build union)
                                                       (guix build utils))
                                #~(begin
                                    (use-modules (guix build union)
                                                 (guix build utils))
                                    (let* ((packages '#$packages)
                                           (find-lib-directories-in-single-package
                                            (lambda ()
                                              (find-files (string-append package "/lib")
                                                          (lambda (file stat)
                                                            (eq? 'directory (stat:type stat)))
                                                          #:stat stat
                                                          #:directories? #t)))
                                           (find-lib-directories-in-all-packages
                                            (lambda (packages)
                                              (apply append (map (lambda (package)
                                                                   (find-lib-directories-in-single-package package))
                                                                 packages))))
                                           (fhs-lib-dirs (find-lib-directories-in-all-packages packages)))
                                      (with-output-to-file #$output
                                        (lambda _
                                          (format #t (string-join fhs-lib-dirs "\n"))
                                          #$output)))))))

(define (ld.so.conf->ld.so.cache ld-conf)
  (computed-file "ld.so.cache" (with-imported-modules `((guix build utils))
                                 #~(begin
                                     (use-modules (guix build utils))
                                     (let* ((ldconfig (string-append #$glibc-for-fhs "/sbin/ldconfig")))
                                       (invoke ldconfig "-X" "-f" #$ld-conf "-C" #$output))))))

(define (packages->ld.so.cache packages)
  (ld.so.conf->ld.so.cache (packages->ld.so.conf packages)))

(define-record-type* <fhs-configuration>
  fhs-configuration
  make-fhs-configuration
  fhs-configuration?
  (lib-packages fhs-configuration-lib-packages
                (default '()))
  (additional-profile-packages fhs-configuration-additional-profile-packages
                               (default '()))
  (additional-special-files fhs-configuration-additional-special-files
                            (default '())))

(define* (union name packages #:key options)
  (computed-files name (with-imported-modules `((guix build union))
                         #~(begin
                             (use-modules (guix buiild union))
                             (union-build #$output '#$packages)))
                  #:options options))

(define* (fhs-lib-union packages #:key system)
  (let* ((name (if system
                   (string-append "fhs-libs-" system)
                   "fhs-libs")))
    (union name packages #:options `(#:system ,system))))

(define (fhs-special-files-service config)
  (let* ((fhs-lib-packages (fhs-configuration-lib-packages config))
         (fhs-lib-package-unions (append fhs-lib-packages `(,(fhs-libs-union fhs-lib-packages #:system "i686-linux"))))
         (fhs-glibc-special-files
          `(("/etc/ld.so.cache" ,(packages->ld.so.cache fhs-lib-package-unions))
            ("/etc/ld.so.conf" ,(packages->ld.so.conf fhs-lib-package-unions))
            ("/lib64/ld-linux-x86-64.so.2" ,(file-append (canonical-package glibc-for-fhs) "/lib/ld-linux-x86-64.so.2"))
            ("/lib/ld-linux.so.2" ,(file-append (canonical-package (32bit-package glibc-for-fhs)) "/lib/ld-linux.so.2"))))
         (fhs-additional-special-files (fhs-configuration-additional-special-files config)))
    (append fhs-glibc-special-files fhs-additional-special-files)))

(define (fhs-profile-service config)
  (fhs-configuration-additional-profile-packages config))

(define fhs-binaries-compatibility-service-type
  (service-type (name 'fhs-compatibility-service)
                (extensions
                 (list (service-extension special-files-service-type fhs-special-files-service)
                       (service-extension profile-service-type fhs-profile-service)))
                (description "Support binaries compiled for the filesystem hierarchy standard.")
                (default-value (fhs-configuration))))
