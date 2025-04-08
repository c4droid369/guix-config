(define-module (hosts workstation)
  #:use-module (gnu)
  #:use-module (guix channels)
  #:use-module (guix utils)

  #:use-module (gnu packages bash)
  #:use-module (gnu packages certs)
  #:use-module (gnu packages shells)

  #:use-module (gnu services base)
  #:use-module (gnu services desktop)
  #:use-module (gnu services networking)
  #:use-module (gnu services ssh)
  #:use-module (gnu services dbus))

;; Guix channel
(define %guix-channel
  (channel
   (name 'guix)
   (url "https://mirror.nju.edu.cn/git/guix.git")
   (branch "master")
   (introduction
    (make-channel-introduction
     "9edb3f66fd807b096b48283debdcddccfea34bad"
     (openpgp-fingerprint
      "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))

;; Helper function
(define* (btrfs-subvolume subvol mount-point #:key (options '()) (needed-for-boot? #f) (deps '()))
  (file-system
    (device "/dev/mapper/cryptgnu")
    (mount-point mount-point)
    (type "btrfs")
    (options (string-append "subvol=" subvol
                            (if (null? options)
                                ""
                                (string-append "," (string-join options ",")))))
    (needed-for-boot? needed-for-boot?)
    (dependencies deps)))

;; Subvolume list
(define %subvol-list
  `(("@" "/"
     #:options ("compress=zstd:3")
     #:needed-for-boot? #t
     #:deps ((mapped-devices)))
    ("@store" "/gnu/store"
     #:options ("nodatacow" "compress=zstd:3" "autodefrag" "space_cache=v2")
     #:deps ((file-system->mapped-device (car file-systems))))
    ("@home" "/home"
     #:options ("compress=zstd:1" "autodefrag"))
    ("@swap" "/swap"
     #:options ("nodatacow"))
    ("@log" "/var/log"
     #:options ("compress=zstd:3"))))

;; Personal key
(define %person-key-c4droid
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB3ALQ8ZJ9yq1f3WOvyph25/SClAf4XQzzZgUVXEcyK")

(operating-system
  (host-name "Workstation")
  (locale "en_US.UTF-8")
  (timezone "Asia/Shanghai")
  (keyboard-layout (keyboard-layout "us"))

  (bootloader (bootloader-configuration
	           (bootloader grub-efi-bootloader)
	           (targets '("/boot/efi"))
	           (timeout 5)
	           (keyboard-layout keyboard-layout)))
  (kernel-arguments '("rootfstype=btrfs"))
  (initrd (lambda (file-systems . rest)
            (apply base-initrd
                   file-systems
                   #:extra-modules '("dm-crypt" "btrfs")
                   rest)))
  (initrd-modules (append (list "dm-crypt" "btrfs" "mptspi") %base-initrd-modules))

  (mapped-devices (list (mapped-device
                         (source (uuid "f142aee1-7cdc-41e0-9d79-a6d70d962387"))
                         (target "cryptgnu")
                         (type luks-device-mapping))))
  (file-systems (cons*
                 (append (map (lambda (s)
                                (apply btrfs-subvolume (car s) (cadr s) (cddr s)))
                              %subvol-list)
                         (list (file-system
                                 (device "/dev/sda1")
                                 (mount-point "/boot/efi")
                                 (type "vfat")
                                 (needed-for-boot? #t)))
                         %base-file-systems)))
  (swap-devices (list (swap-space
		               (target "/swap/swapfile")
		               (dependencies file-systems))))
  
  (users (cons (user-account
		        (name "c4droid")
		        (comment "Guix user")
		        (group "users")
		        (home-directory "/home/c4droid")
		        (shell #~(string-append #$bash "/bin/bash"))
		        (supplementary-groups '("wheel" "netdev" "input" "cdrom" "audio" "video" "tty")))
	           %base-user-accounts))
  
  (packages (append (map specification->package+output
			             '("tmux"
			               "git-minimal"
			               "btrfs-progs"
			               "gnupg"
			               "curl"
			               "wget"
			               "dbus"
			               "openssl"
			               "dosfstools"))
		            %base-packages))
  
  (services (append (list (service dhcp-client-service-type)
			              (service openssh-service-type
				                   (openssh-configuration
				                    (x11-forwarding? #t)
				                    (permit-root-login #f)
				                    (password-authentication? #f)
				                    (public-key-authentication? #t)
				                    (authorized-keys
				                     `(("c4droid" ,(plain-file "c4droid" %person-key-c4droid))))))
                          (service elogind-service-type)
                          (service ntp-service-type
                                   (ntp-configuration
                                    (allow-large-adjustment? #t))))
		            (modify-services %base-services
                      (guix-service-type config => (guix-configuration
                                                    (inherit config)
                                                    (channels (list %guix-channel))))))))
