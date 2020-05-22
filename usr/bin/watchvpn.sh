#!/bin/sh
#
# Copyright (C) 2020 dimfish
#
# This is free software, licensed under the GNU General Public License v2.
#

watchvpn() {
	local period="$1"; local pinghosts="$2"; local ifname="$3"; local pingperiod="$4"

	time_chk=$(time_now)
	time_chk_inet=$time_chk

	while true
	do
		time_diff="$(($(time_now)-time_chk))"

		[ "$time_diff" -lt "$pingperiod" ] && {
			sleep_time="$((pingperiod-time_diff))"
			sleep "$sleep_time"
		}

		time_chk=$(time_now)

		for host in $pinghosts
		do
			if ping -c 1 "$host" &> /dev/null
			then
				time_chk=$(time_now)
				time_chk_inet=$time_chk
			else
				time_diff="$(($(time_now)-time_chk_inet))"
				logger -p daemon.info -t "watchvpn[$$]" "no $ifname connectivity for $time_diff seconds. Reseting when reaching $period"
			fi
		done

		time_diff="$(($(time_now)-time_chk_inet))"
		[ "$time_diff" -ge "$period" ] && {
			logger -p daemon.info -t "watchvpn[$$]" "Restarting $ifname"
			ifdown "$ifname" && ifup "$ifname"

			time_chk=$(time_now)
			time_chk_inet=$time_chk
		}
	done
}

time_now() {
	echo "$(cut -f1 -d. /proc/uptime)"
}

watchvpn "$1" "$2" "$3" "$4"
