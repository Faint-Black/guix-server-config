;;============================================================================;;
;;                                                                            ;;
;;              My personal server-oriented GuixSD config file.               ;;
;;                                                                            ;;
;;============================================================================;;

(use-modules (gnu)
             (gnu packages)
             (gnu packages linux)
             (gnu packages networking)
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
             (gnu packages emacs)
             (gnu packages emacs-xyz)
             (gnu services)
             (gnu services security)
             (gnu services dbus)
             (gnu services cups)
             (gnu services desktop)
             (gnu services networking)
             (gnu services ssh)
             (gnu services xorg)
             (gnu services docker))

(define %packagelist-essential
  %base-packages)

(define %packagelist-codecs
  (list ffmpeg))

(define %packagelist-networking
  (list fail2ban
        curl
        wget
        netcat
        nmap
        nginx))

(define %packagelist-administration
  (list btop
        bmon
        dbus
        elogind
        fastfetch
        turbostat))

(define %packagelist-development
  (list git
        (specification->package "make")
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
        docker-compose))

(define %packagelist-emacs
  (list emacs
        emacs-guix
        emacs-company
        emacs-magit
        emacs-org
        emacs-vterm))

(define %servicelist-essential
  (append
   %base-services
   (list (service dhcpcd-service-type)
         (service ntp-service-type))))

(define %servicelist-ssh
  (list
   ;; 'fail2ban-jail-service' is a wrapper function that defines
   ;;both the fail2ban method and its subclass, which in this
   ;;case is openssh. So no need to redefine it elsewhere
   (service
    (fail2ban-jail-service
     openssh-service-type
     (fail2ban-jail-configuration (name "sshd")
                                  (enabled? #t)
                                  (max-retry 10)
                                  (ban-time "10m")
                                  (ban-time-increment? #f)))
    (openssh-configuration (port-number 22)
                           (max-connections 5)
                           (permit-root-login #f)
                           (accepted-environment (list "COLORTERM"))))))

(define %servicelist-docker
  (list
   ;; All docker dependencies
   (service elogind-service-type)
   (service dbus-root-service-type)
   (service containerd-service-type)
   (service docker-service-type)))



;;---------------------------------------------------------------------------;;
;; Here begins the actual system definition.                                 ;;
;;---------------------------------------------------------------------------;;
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
                 (supplementary-groups '("wheel" "netdev" "audio" "video")))
   %base-user-accounts))
 ;;---------------------------------------------------------------------------;;
 ;; List of system packages and daemon services (defined previously).         ;;
 ;;---------------------------------------------------------------------------;;
 (packages (append %packagelist-essential
                   %packagelist-codecs
                   %packagelist-networking
                   %packagelist-administration
                   %packagelist-development
                   %packagelist-emacs))
 (services (append %servicelist-essential
                   %servicelist-ssh
                   %servicelist-docker))
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
