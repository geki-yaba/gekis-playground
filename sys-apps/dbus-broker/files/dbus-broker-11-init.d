#!/sbin/openrc-run
# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License, v2 or later

extra_started_commands="reload"

description="An IPC message bus daemon"
pidfile="/var/run/dbus.pid"
command="/usr/bin/dbus-broker-launch"
command_args="--scope system --audit --verbose"

dbus_socket="/var/run/dbus/system_bus_socket"

depend() {
	need localmount
	after bootmisc
}

start_pre() {
	/usr/bin/dbus-uuidgen --ensure=/etc/machine-id

	# We need to test if /var/run/dbus exists,
	# since script will fail if it does not
	checkpath -q -d /var/run/dbus

	export DBUS_SYSTEM_BUS_ADDRESS="${dbus_socket}"
}

stop_post() {
	[ ! -S "${dbus_socket}" ] || rm -f "${dbus_socket}"
}

reload() {
	ebegin "Reloading D-BUS broker messagebus config"
	/usr/bin/busctl --system --no-pager call \
		org.freedesktop.DBus /org/freedesktop/DBus \
		org.freedesktop.DBus ReloadConfig > /dev/null
	eend $?
}
