# Bin Executability Guide

Here is a simple, technical guide on how to make these bash scripts executable directly by the Linux kernel (as real `/bin/` or `/sbin/` programs in your Lumen distro).

- Place each script in the correct directory on your target root filesystem
  - Most utilities → `/bin/`
  - System/admin tools (mount, umount, insmod, init, etc.) → `/sbin/`

- Name the file without any extension
Example:
  - /bin/cat
  - /bin/grep
  - /sbin/mount
  - /sbin/init

- Make sure the very first line of every file is exactly this shebang (no extra spaces):
```
#!/bin/bash
```

- After copying or creating the file, set the executable bits:
```
chmod 755 /path/to/the/file
```
(or `chmod +x /path/to/the/file`)

- Common safe permissions for these utilities in a minimal distro:
  - Normal commands (`ls`, `cat`, `grep`, `cp`, etc.) → `755` (rwxr-xr-x)
  - Admin/system tools (`mount`, `umount`, `insmod`, `init`) → `755` is still fine in most rescue/live images

- If you are building the image inside a chroot or on another machine, remember to run these commands inside the target root filesystem (not on the host):
```
chroot /mnt/lumen-root /bin/bash
cd /bin
chmod 755 cat grep cp rm sed sh ...
```

- For `/sbin/init` specifically (PID 1):
  - The kernel **requires** the file to have the executable bit set
  - The kernel does **not** care about the shebang line format (as long as it starts with `#!`)
  - But `/bin/bash` must already exist and be executable when the kernel tries to run `/sbin/init`

- Quick checklist after placing all files:
```
ls -l /bin/cat      → should show -rwxr-xr-x
ls -l /sbin/init    → should show -rwxr-xr-x
file /bin/ls        → should say: Bourne-Again shell script ...
head -n 1 /bin/mount → should show #!/bin/bash
```

- Optional but recommended in a flashable/minimal distro:
  - Run `strip` on any real compiled binaries (not needed for bash scripts)
  - Create symlinks for common aliases:
```
ln -s busybox /bin/sh          (if using busybox)
ln -s bash /bin/sh
ln -s ls /bin/dir
ln -s mount /bin/mountpoint
```

- Final test (after booting the image):
```
/bin/ls --help          → should show your custom help
/bin/cat /proc/version  → should work
/sbin/mount             → should at least show current mounts or error cleanly
```

Follow these steps and the kernel will happily execute your bash-based utilities as real programs.