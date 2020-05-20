#!/bin/sh
#
# Copyright (C) 2020 dimfish
#
# This is free software, licensed under the GNU General Public License v2.
#

watchvpn_ping() {
	local period="$1"; local pinghosts="$2"; local ifname="$3"; local pingperiod="$4"

	time_now="$(cat /proc/uptime)"
	time_now="${time_now%%.*}"
	time_lastcheck="$time_now"
	time_lastcheck_withinternet="$time_now"

	while true
	do
		time_now="$(cat /proc/uptime)"
		time_now="${time_now%%.*}"
		time_diff="$((time_now-time_lastcheck))"

		[ "$time_diff" -lt "$pingperiod" ] && {
			sleep_time="$((pingperiod-time_diff))"
			sleep "$sleep_time"
		}

		time_now="$(cat /proc/uptime)"
		time_now="${time_now%%.*}"
		time_lastcheck="$time_now"

		for host in $pinghosts
		do
			if ping -c 1 "$host" &> /dev/null
			then
				time_lastcheck_withinternet="$time_now"
			else
				time_diff="$((time_now-time_lastcheck_withinternet))"
				logger -p daemon.info -t "watchvpn[$$]" "no VPN connectivity for $time_diff seconds. Reseting when reaching $period"
			fi
		done

		time_diff="$((time_now-time_lastcheck_withinternet))"
		[ "$time_diff" -ge "$period" ] && {
			logger -p daemon.info -t "watchvpn[$$]" "Restarting $ifname"
			ifdown "$ifname" && ifup "$ifname"
			time_lastcheck="$time_now"
			time_lastcheck_withinternet="$time_now"
		}
	done
}

watchvpn_ping "$1" "$2" "$3" "$4"
