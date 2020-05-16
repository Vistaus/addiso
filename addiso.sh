#!/bin/bash

# Grub image adder by Don B. Cilly (donbcilly@gmail.com) #
########### This script will add an entry to your grub boot menu for the ISO selected by the Dolphin Service Menu ##########
########### It will not work if not called from it ##########
###########
########### This is the live version ###########
########### To just test it, comment out the "echo "$grubentry" | sudo tee -a /etc/grub.d/40_custom" line ##########
########### and uncomment the following one  ###########
########### Do the same for the"sudo update-grub" one  ###########
isoentry="$1";isoshort="${isoentry##*/}"
echo A couple of checks:
part=$(df -P . | sed -n '$s/[[:blank:]].*//p')
par2=$(df -P / | sed -n '$s/[[:blank:]].*//p')

if [ "$part" == "$par2" ]; then
     isoinfo="$isoentry"
else 
     pw=$(echo $PWD | awk '{ print $1 }' | cut -c 6-)
     isoinfo="$pw"/"$isoshort"
fi

FILE=$(which iso-info)
if [ -f "$FILE" ]; then
    echo "$FILE exist." $'\e[0;36m' "OK."$'\e[0;37m'
else 
    echo "iso-info is" $'\e[0;31m' "not installed." $'\e[0;37m' "Please [sudo apt] install libcdio-utils and run this again.";exit
fi

echo
p1=${part:7:1};p2=${part:8:1};p3=$(tr abcdefghij 0123456789 <<< "$p1");p4="hd"$p3,$p2
ptype=${part:5:1}
lz=$(iso-info -l -i $isoentry | grep -i initrd | awk '{ print $NF}')
case $ptype in 
n) p1=${part:9:1};p2=${part:13:1};p4="hd"$p1,$p2                   ;;
s) p1=${part:7:1};p2=${part:8:1};p3=$(tr abcdefghij 0123456789 <<< "$p1");p4="hd"$p3,$p2                         ;;
esac
echo The partition your ISO is on is $'\e[0;32m' $part $'\e[0;37m'
echo "grub notation": $p4
echo
grbv=$(grub-install --version  | awk '/(GRUB)/ {print substr($3,4,1)}')
case $grbv in 
2) echo Your grub version is $'\e[0;32m' "2.0"$grbv".  OK." $'\e[0;37m'

grubentry="$(cat <<-EOF
#
#
#!/bin/sh
exec tail -n +3 \$0
menuentry "$isoshort" {
        set isofile="$isoinfo"
        loopback loop ($p4)\$isofile
        linux (loop)/casper/vmlinuz boot=casper iso-scan/filename=\$isofile noprompt noeject toram
        initrd (loop)/casper/$lz
}
EOF
)"              ;;
4) echo Your grub version is $'\e[0;32m' "2.0"$grbv". Grub 2.04" $'\e[0;33m'"may" $'\e[0;32m'"have problems with loopack devices, but it's probably OK.." $'\e[0;37m'
echo
isoentry="$1"
grubentry="$(cat <<-EOF
#
#
#!/bin/sh
exec tail -n +3 \$0
menuentry "$isoshort" {
        set isofile="$isoinfo"
        rmmod tpm
        loopback loop ($p4)\$isofile
        linux (loop)/casper/vmlinuz boot=casper iso-scan/filename=\$isofile noprompt noeject toram
        initrd (loop)/casper/$lz
}
EOF
)"             ;;
esac
echo $'\e[0;36m'The following entry will be added to to /etc/grub.d/40_custom... $'\e[0;37m'
echo "$grubentry" $'\e[0;36m' 
#read -rsn1 -p"Press any key to continue";echo
while true; do
    read -p "Does that look correct? y/n: " yn
    case $yn in
        [Nn]* ) echo Close the window to exit.;exit;;
        [Yy]* ) echo "$grubentry" | sudo tee -a /etc/grub.d/40_custom ;echo $'\e[0;37m' ;echo "Entry added. Let's update grub then." $'\e[0;36m' ; break;;
    esac
done

#echo "$grubentry" >>~/.local/share/kservices5/ServiceMenus/customentry.txt ## This is the line for testing purposes :·)
echo
echo
echo
while true; do
    read -p "Would you like to update grub? y/n: " yn
    case $yn in
        [Nn]* ) echo Close the window to exit.;exit;;
        [Yy]* ) echo OK.; break ;;
    esac
done
echo
echo "Updating grub..."
echo $'\e[0;37m'
sudo update-grub ## This is the actual line
#ls -la ## This is the line for testing purposes :·)
echo $'\e[0;36m'
echo "Let's check. "
echo "These are the last 24 lines of /boot/grub/grub.cfg:"
echo $'\e[0;37m'
tail -24 /boot/grub/grub.cfg
echo $'\e[0;36m'
echo "You should find an entry for "$isoshort" in your grub menu that should boot the OS"
echo
echo Close the window to exit.
