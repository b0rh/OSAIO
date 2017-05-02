FROM scratch
MAINTAINER "b0rh" <francisco@garnelo.eu>

ADD openwrt-rootfs.tar.gz /

# Configures terminal
RUN echo "export TERM=xterm-256color" >> /etc/profile

## Set debug level to avoid boot problems
#RUN mkdir -p /tmp &&\
#    echo 4 > /tmp/debug_level

#RUN rm /dev/sd*
#RUN rm /dev/dm*
#RUN rm /dev/md* -rf
#RUN rm /dev/vg0 -rf
#RUN rm /dev/sg*
#RUN rm /dev/kvm
#RUN rm /dev/kmsg
#RUN rm /dev/kcore

# Create missing directories
RUN mkdir -pv /var/run
RUN mkdir -pv /var/lock



# Preinit traces
#RUN echo "echo '02_default_set_state'" >> /lib/preinit/02_default_set_state &&\
#    echo "echo '10_indicate_failsafe'" >> /lib/preinit/10_indicate_failsafe &&\
#    echo "echo '10_indicate_preinit'" >> /lib/preinit/10_indicate_preinit &&\
#    echo "echo '10_sysinfo'" >> /lib/preinit/10_sysinfo &&\
#    echo "echo '15_essential_fs_x86'" >> /lib/preinit/15_essential_fs_x86 &&\
#    echo "echo '20_sysinfo'" >> /lib/preinit/20_sysinfo &&\
#    echo "echo '30_failsafe_wait'" >> /lib/preinit/30_failsafe_wait &&\
#    echo "echo '40_run_failsafe_hook'" >> /lib/preinit/40_run_failsafe_hook &&\
#    echo "echo '50_indicate_regular_preinit'" >> /lib/preinit/50_indicate_regular_preinit &&\
#    echo "echo '70_initramfs_test'" >> /lib/preinit/70_initramfs_test &&\
#    echo "echo '79_move_config'" >> /lib/preinit/79_move_config &&\
#    echo "echo '80_mount_root'" >> /lib/preinit/80_mount_root &&\
#    echo "echo '99_10_failsafe_login'" >> /lib/preinit/99_10_failsafe_login &&\
#    echo "echo '99_10_run_init'" >> /lib/preinit/99_10_run_init

# Remove all modules
RUN rm /lib/modules/*/*

# Fix x86 boot and introduce a delay to give time to set container enviroment
#RUN    rm /lib/preinit/02_default_set_state
#RUN    rm /lib/preinit/10_indicate_preinit
#RUN    rm /lib/preinit/20_check_iso
#RUN    rm /lib/preinit/80_mount_root
RUN rm /lib/preinit/* &&\
    echo 'ubusd &' >> /lib/preinit/00_fix_x86_boot &&\
    #echo 'echo $(export)' >> /lib/preinit/00_fix_x86_boot &&\
    #echo 'echo $(pwd)' >> /lib/preinit/00_fix_x86_boot &&\
    #echo 'echo $(ps)' >> /lib/preinit/00_fix_x86_boot &&\
    echo "for S in /etc/init.d/* ; do \$S enabled && \$S start; done" >> /lib/preinit/00_fix_x86_boot
    #echo "sh -c 'source /etc/profile; for sct in \$(find /etc/rc.d -name 'S*') ; do \$sct start; sleep 2;done'" >> /lib/preinit/00_fix_x86_boot
    #echo "sh -c 'for sct in \$(find /etc/rc.d -name 'S*') ; do \$sct start; sleep 2;done'" >> /lib/preinit/00_fix_x86_boot

    #echo 'for sct in $(find /etc/rc.d -name 'S*') ; do $sct start;done' >> /lib/preinit/00_fix_x86_boot

    #echo 'cd /etc/rc.d' >> /lib/preinit/00_fix_x86_boot &&\
    #echo 'for sct in $(ls /etc/rc.d | grep 'S') ; do ./$sct restart;done' >> /lib/preinit/00_fix_x86_boot


## InitRC traces
#RUN echo 'echo 'S10boot'' >> /etc/rc.d/S10boot &&\
#    echo 'echo 'S10system'' >> /etc/rc.d/S10system &&\
#    echo 'echo 'S12log'' >> /etc/rc.d/S12log &&\
#    echo 'echo 'S19firewall'' >> /etc/rc.d/S19firewall &&\
#    echo 'echo 'S20network'' >> /etc/rc.d/S20network &&\
#    echo 'echo 'S35odhcpd'' >> /etc/rc.d/S35odhcpd &&\
#    echo 'echo 'S50cron'' >> /etc/rc.d/S50cron &&\
#    echo 'echo 'S50dropbear'' >> /etc/rc.d/S50dropbear &&\
#    echo 'echo 'S60dnsmasq'' >> /etc/rc.d/S60dnsmasq &&\
#    echo 'echo 'S95done'' >> /etc/rc.d/S95done &&\
#    echo 'echo 'S98sysntpd'' >> /etc/rc.d/S98sysntpd
#
#RUN echo 'echo 'rc.local'' > /etc/rc.local &&\
#    echo 'exit' >> /etc/rc.local

# Disable services (InitRC)
RUN rm /etc/rc.d/K10gpio_switch &&\
    rm /etc/rc.d/S98gpio_switch &&\
    rm /etc/rc.d/S96led &&\
    rm /etc/rc.d/S11sysctl &&\
    rm /etc/rc.d/S00sysfixtime &&\
    rm /etc/rc.d/K90sysfixtime
    #rm /etc/rc.d/K50dropbear &&\
    #rm /etc/rc.d/K85odhcpd &&\
    #rm /etc/rc.d/K89log &&\
    #rm /etc/rc.d/K90network &&\
    #rm /etc/rc.d/K98boot &&\
    #rm /etc/rc.d/K99umount &&\
    #rm /etc/rc.d/S10boot &&\
    #rm /etc/rc.d/S10system &&\
    #rm /etc/rc.d/S12log &&\
    #rm /etc/rc.d/S19firewall &&\
    #rm /etc/rc.d/S20network &&\
    #rm /etc/rc.d/S35odhcpd &&\
    #rm /etc/rc.d/S50cron &&\
    #rm /etc/rc.d/S50dropbear &&\
    #rm /etc/rc.d/S60dnsmasq &&\
    #rm /etc/rc.d/S95done &&\
    #rm /etc/rc.d/S98sysntpd &&\
    #rm /etc/rc.d/S12rpcd &&\

#RUN mkdir /var/lock
USER root
#ENTRYPOINT /bin/sh
CMD /sbin/init
