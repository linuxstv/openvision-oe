FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

RDEPENDS_ntpdate += "lockfile-progs"

do_install_append() {
    perl -0777 -i -pe 's:(\. /etc/default/ntpdate.+?fi):$1\n\nif test -f /var/tmp/ntpv4.local ; then\n. /var/tmp/ntpv4.local\nfi\n\ncheck_online() {\n\tcount=0\n\twhile [ \$count -lt 5 ]; do\n\t\tsleep 0.5\n\t\tif ping -4 -c 1 www.google.com >/dev/null 2>&1 \|\| ping -6 -c 1 www.google.com \>/dev/null 2\>&1; then\n\t\t\tbreak\n\t\tfi\n\t\tcount=\$((count+1))\n\tdone\n}\n\nif [ "\$NTPV4" != "" ]; then\n\tNTPSERVERS=\$NTPV4\nfi:s;' \
                 ${D}${bindir}/ntpdate-sync

	# When invoked from ifup, step to the time rather than slewing
	perl -0777 -i -pe 's:# This is a heuristic.*? then:DELAY=""\n\n# This is a heuristic\: Interfaces are usually brought up during boot, so this is\n# the right time to quickly step to the right time, rather than slewing to it.\nif [ "\$0" = "/etc/network/if-up.d/ntpdate-sync" ]; then\n\tDELAY="check_online":s;' \
                 ${D}${bindir}/ntpdate-sync

	# When invoked from ifup, wait for network to really be up
	# Previously execution via ifup ALWAYS failed.
	perl -i -pe 's:(if /usr/sbin/ntpdate -s):\$DELAY\n\n$1:;' \
                 ${D}${bindir}/ntpdate-sync

	# Only invoke hwclock if it is executable and use stb-hwclock instead ...
	perl -i -pe 's:(if \[ "\$UPDATE_HWCLOCK" = "yes" \]);:$1 && [ -x /sbin/stb-hwclock ];:;' \
                -pe 's:(\s)(hwclock --systohc):$1/sbin/stb-$2:;' \
                 ${D}${bindir}/ntpdate-sync
}

pkg_postinst_ntpdate() {
#!/bin/sh

if [ -n "$D" ]; then
    $INTERCEPT_DIR/postinst_intercept delay_to_first_boot ntpdate mlprefix=
    exit 0
fi
set +e
if ! grep -q -s ntpdate ${localstatedir}/spool/cron/crontabs/root; then
    echo "adding crontab"
    test -d $D${localstatedir}/spool/cron/crontabs || mkdir -p ${localstatedir}/spool/cron/crontabs
    echo "30 * * * *    ${bindir}/ntpdate-sync silent" >> ${localstatedir}/spool/cron/crontabs/root
fi
}
