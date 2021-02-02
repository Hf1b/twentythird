# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/platform/13500000.dwmmc0/by-name/boot;
dtboblock=/dev/block/platform/13500000.dwmmc0/by-name/dtbo;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel install
dump_boot;
ui_print " * Installig kernel"
write_boot;

mount -o rw,remount /system_root
mount /vendor

cfs_rc=/system_root/init.usb.configfs.rc

# GSI scenario
if [[ -f "GSI" ]]; then
  ui_print " * Type: GSI"

  # Exynos 7904 check
  if [[ -f "/vendor/etc/init/init.exynos7904.usb.rc" ]] && [[ -f "$cfs_rc" ]]; then
    backup_file $cfs_rc
    replace_file $cfs_rc 750 init.usb.configfs.rc

    ui_print " * ADB & MTP fix is applied"
  fi
fi

if [[ -f "OneUI" ]]; then
  ui_print " * Type: OneUI"
fi

umount /system_root
umount /vendor

ui_print " * Kernel is installed"
## end install
