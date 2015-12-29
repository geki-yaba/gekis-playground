# gekis-playground
The playground of gekis hacking on Gentoo Linux distribution.

System composed of EFI-based kernel, sysvinit/old openrc/eudev-based startup process and lightdm/mate desktop experience.

Featured by wpa_supplicant/dhcpcd-transparent network connections
and seamless switch of display/audio from internal components to hdmi.

Here are some useful commands and configurations, which are described in a good wiki of a proper distribution.

## wpa_supplicant: configure connection once
```bash
ip link set wlp1s0 up
iwconfig wlp1s0 essid <ssid>
wpa_passphrase <ssid> >> /etc/wpa_supplicant/wpa_supplicant.conf
ifconfig wlp1s0
```

## udev: reload rules
```bash
udevadm control --reload
```

## udev: switch display/audio(pulseaudio) to hdmi

~ cat /etc/udev/rules.d/90-display.rules
```bash
ACTION=="change", SUBSYSTEM=="drm", RUN+="display.sh &"
```
~ cat /lib64/udev/display.sh
```bash
#!/bin/sh

# config
DISPLAY=":0"

# function
function select_display()
{
	local mode="default"

	# add tests for other cards
        if [ "connected" == "$(/bin/cat /sys/class/drm/card0-HDMI-A-1/status)" ]
        then
        	mode="hdmi"
        #elif  [ other card ]
        fi

        case "${mode}"
        in
        "hdmi")
                /usr/bin/xrandr --output HDMI1 --auto --output LVDS1 --off
                /bin/su ${USER} -c "/usr/bin/pacmd set-card-profile alsa_card.pci-0000_00_1b.0 output:hdmi-stereo+input:analog-stereo"
                ;;
        *)
                /usr/bin/xrandr --output LVDS1 --auto --output HDMI1 --off
                /bin/su ${USER} -c "/usr/bin/pacmd set-card-profile alsa_card.pci-0000_00_1b.0 output:analog-stereo+input:analog-stereo"
                ;;
        esac
}

# execute
USER="$(/usr/bin/w -husf|/usr/bin/awk "\$2 == \"${DISPLAY}\" {print \$1; exit 3}")"

if [ ${?} -eq 3 ]
then
        XAUTHORITY="/home/${USER}/.Xauthority"
        PULSE_RUNTIME_PATH="$(/bin/ls -ld /tmp/pulse-*|/usr/bin/awk "\$3 == \"${USER}\" {print \$9; exit 3}")"

        if [ ${?} -eq 3 ]
        then
                export DISPLAY XAUTHORITY PULSE_RUNTIME_PATH

                select_display
        fi
fi

exit 0
```
