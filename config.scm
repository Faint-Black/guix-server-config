;;============================================================================;;
;;                                                                            ;;
;;              My personal server-oriented GuixSD config file.               ;;
;;                                                                            ;;
;;============================================================================;;

(use-modules (gnu)
             (gnu packages)
             (gnu packages linux)
             (gnu packages networking)
             (gnu packages compression)
             (gnu packages file)
             (gnu packages dns)
             (gnu packages autotools)
             (gnu packages freedesktop)
             (gnu packages web)
             (gnu packages video)
             (gnu packages admin)
             (gnu packages glib)
             (gnu packages gcc)
             (gnu packages zig)
             (gnu packages perl)
             (gnu packages python)
             (gnu packages docker)
             (gnu packages curl)
             (gnu packages wget)
             (gnu packages rsync)
             (gnu packages version-control)
             (gnu packages java)
             (gnu packages slang)
             (gnu packages emacs)
             (gnu packages emacs-xyz)
             (gnu packages luanti)
             (gnu services)
             (gnu services security)
             (gnu services shepherd)
             (gnu services dbus)
             (gnu services cups)
             (gnu services desktop)
             (gnu services networking)
             (gnu services ssh)
             (gnu services xorg)
             (gnu services docker))

(define %packagelist-essential
  (list
   ;; codecs and compression
   ffmpeg
   unzip
   tar
   ;; networking
   fail2ban
   curl
   wget
   netcat
   nmap
   nginx
   ;; administration
   most
   btop
   bmon
   dbus
   elogind
   fastfetch
   turbostat
   tree
   ;; development
   git
   gnu-make
   autoconf
   automake
   perl
   perl-json
   perl-json-parse
   python
   gcc
   zig
   openjdk
   containerd
   docker
   docker-cli
   docker-compose
   ;; emacs
   emacs
   emacs-guix
   emacs-company
   emacs-magit
   emacs-org
   emacs-vterm
   ;; misc
   luanti-server))

(define %servicelist-essential
  (list
   ;; net
   (service dhcpcd-service-type)
   (service ntp-service-type)
   ;; docker
   (service elogind-service-type)
   (service dbus-root-service-type)
   (service containerd-service-type)
   (service docker-service-type)))

;; 'fail2ban-jail-service' is a wrapper function that defines
;;both the fail2ban method and its subclass, which in this
;;case is openssh. So no need to redefine it elsewhere
(define %servicelist-ssh
  (list
   (service
    (fail2ban-jail-service
     openssh-service-type
     (fail2ban-jail-configuration (name "sshd")
                                  (enabled? #t)
                                  (max-retry 10)
                                  (ban-time "50m")
                                  (ban-time-increment? #f)))
    (openssh-configuration (port-number 22)
                           (max-connections 5)
                           (permit-root-login #f)
                           (accepted-environment (list "COLORTERM"))))))

;; ddclient user binary shepherd service, does nothing if it doesn't exist
(define %servicelist-ddclient
  (if (file-exists? "/usr/bin/ddclient")
      (list
       (simple-service
        'ddclient-service shepherd-root-service-type
        (list
         (shepherd-service
          (auto-start? #t)
          (documentation "ddclient daemon")
          (provision '(ddclient))
          (requirement '(networking user-processes))
          (start
           #~(make-forkexec-constructor
              '("/usr/bin/ddclient"
                "--daemon" "600"
                "--file" "/home/cezar/Desktop/ddclient/ddclient.conf"
                "--foreground")
              #:environment-variables
              (list
               "HOME=/home/cezar"
               "PATH=/run/privileged/bin:/home/cezar/.config/guix/current/bin:/home/cezar/.guix-home/profile/bin:/home/cezar/.guix-profile/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin"
               "SSL_CERT_DIR=/run/current-system/profile/etc/ssl/certs"
               "SSL_CERT_FILE=/run/current-system/profile/etc/ssl/certs/ca-certificates.crt"
               "PERL5LIB=/run/current-system/profile/lib/perl5/site_perl")))
          (stop
           #~(make-kill-destructor))))))
      '()))


;;============================================================================;;
;; HERE BEGINS THE ACTUAL SYSTEM DEFINITION.                                  ;;
;;============================================================================;;
(operating-system
 (locale "en_US.utf8")
 (timezone "America/Sao_Paulo")
 (keyboard-layout (keyboard-layout "br"))
 (host-name "guix")
 (kernel-arguments '("quiet" "modprobe.blacklist=radeon,amdgpu"))
 ;;---------------------------------------------------------------------------;;
 ;; List of users and groups ('root' is implicit).                            ;;
 ;;---------------------------------------------------------------------------;;
 (users
  (cons*
   (user-account (name "cezar")
                 (comment "Cezar")
                 (group "users")
                 (home-directory "/home/cezar")
                 (supplementary-groups '("wheel" "netdev" "audio" "video" "docker")))
   %base-user-accounts))
 ;;---------------------------------------------------------------------------;;
 ;; List of system packages and daemon services (defined previously).         ;;
 ;;---------------------------------------------------------------------------;;
 (packages (append %base-packages
                   %packagelist-essential))

 (services (append %base-services
                   %servicelist-essential
                   %servicelist-ddclient
                   %servicelist-ssh))
 ;;---------------------------------------------------------------------------;;
 ;; Boot/FS/Mounting/Swap/Partition settings. (NOT REPRODUCIBLE)              ;;
 ;;---------------------------------------------------------------------------;;
 (bootloader
  (bootloader-configuration
   (bootloader grub-efi-bootloader)
   (targets (list "/boot/efi"))
   (keyboard-layout keyboard-layout)))

 (swap-devices
  (list (swap-space (target (uuid "1e4cff91-2358-4edb-9c27-06add6d6bf5e")))))

 (file-systems
  (cons*
   (file-system (mount-point "/boot/efi")
                (device (uuid "8203-3FCB" 'fat32))
                (type "vfat"))
   (file-system (mount-point "/")
                (device (uuid "815c6342-ab97-4bec-bb99-fe23c807982a" 'ext4))
                (type "ext4"))
   (file-system (mount-point "/home")
                (device (uuid "20fee2c0-cbbd-4e7f-a02a-68d8d39fafd1" 'ext4))
                (type "ext4"))
   %base-file-systems)))
