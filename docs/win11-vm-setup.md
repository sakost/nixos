# Windows 11 VM Guest Setup

Guide for setting up host-guest integrations in a Windows 11 VM
running on QEMU/KVM via virt-manager.

## Prerequisites (host-side, already configured)

- `virtualisation.libvirtd.qemu.swtpm.enable = true` (TPM for Win11)
- `virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ]` (shared folders)
- `virtualisation.spiceUSBRedirection.enable = true` (USB passthrough)
- `systemd.tmpfiles.rules` for `/var/lib/swtpm-localca` (swtpm cert storage)

## Step 1: Download required ISOs

Before installing Windows, download these:

- **VirtIO drivers ISO**: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
  - Contains disk, network, display, and filesystem drivers for Windows guests
- **Windows 11 ISO**: from Microsoft's official site

## Step 2: Create the VM in virt-manager

1. New VM > Local install media > select Win11 ISO
2. **Before starting install**, click "Customize configuration before install"
3. In the customization screen:
   - **Overview > Firmware**: select UEFI (`OVMF_CODE.secboot.fd`) for Secure Boot
   - **CPUs**: set topology matching your preference (e.g. 8 cores)
   - **Memory**: allocate as needed (8+ GB recommended)
   - **Disk**: Bus type = **VirtIO** (much faster than SATA/IDE)
   - **NIC**: Device model = **virtio**
   - **Add Hardware > Storage**: attach `virtio-win.iso` as CDROM (needed during install for disk drivers)
   - **TPM**: should be auto-configured (swtpm)

## Step 3: Install Windows with VirtIO drivers

During Windows installation:
1. When "Where do you want to install Windows?" shows no drives:
   - Click **Load driver** > Browse > virtio-win CDROM > `viostor\w11\amd64`
   - Select the **Red Hat VirtIO SCSI controller** driver
2. The VirtIO disk now appears — proceed with installation
3. Network won't work yet (that's OK, skip Microsoft account setup)

## Step 4: Install VirtIO guest drivers (post-install)

After Windows boots:
1. Open the virtio-win CDROM in File Explorer
2. Run **`virtio-win-gt-x64.msi`** — installs all VirtIO drivers:
   - VirtIO Serial (host-guest communication channel)
   - VirtIO Balloon (dynamic memory)
   - VirtIO Network (NetKVM)
   - VirtIO Block (viostor)
   - VirtIO SCSI (vioscsi)
   - VirtIO Input (vioinput)
   - VirtIO GPU/Display (viogpu)
   - QXL Display driver
3. Reboot Windows

## Step 5: Install SPICE guest tools

Download and install **SPICE Guest Tools** from:
https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe

This provides:
- **Clipboard sharing** (copy/paste between host and guest)
- **Display auto-resize** (guest resolution follows virt-manager window)
- **SPICE agent** (mouse integration, drag-drop)

Reboot after installation.

## Step 6: Set up shared folders (virtiofs)

### Host side (in virt-manager)

1. Shut down the VM
2. Open VM settings > **Memory** > check **Enable shared memory** (required for virtiofs)
3. **Add Hardware > Filesystem**:
   - Driver: **virtiofs**
   - Source path: `/home/sakost/shared` (or any host directory)
   - Target path: a tag name, e.g. `host-shared` (this is a mount tag, not a path)
4. Start the VM

### Guest side (in Windows)

1. **Install WinFsp** (Windows File System Proxy):
   - Download from https://winfsp.dev/rel/ (latest `.msi`)
   - Install with default options

2. **Install VirtIO-FS driver** (if not already from step 4):
   - Open Device Manager > look for unknown **Mass Storage Controller**
   - Update driver > Browse > virtio-win CDROM > `viofs\w11\amd64`
   - Or it may already be installed by the `virtio-win-gt-x64.msi` package

3. **Start the VirtIO-FS service**:
   - Open Services (`services.msc`)
   - Find **VirtIO-FS Service**, set startup type to **Automatic**
   - Start the service
   - The shared folder appears as a new drive letter (e.g. `Z:`)

### Multiple shared folders

Repeat "Add Hardware > Filesystem" in virt-manager for each folder.
Each gets a unique mount tag. The VirtIO-FS service maps them to
sequential drive letters.

## Step 7: USB device passthrough

With SPICE USB redirection enabled:
1. In virt-manager toolbar: **Virtual Machine > Redirect USB device**
2. Select the device to pass through
3. Device appears in Windows immediately

For permanent passthrough, add the device in VM settings > **Add Hardware > USB Host Device**.

## Troubleshooting

### Shared folder not appearing in Windows
- Verify "Enable shared memory" is checked in VM Memory settings
- Check VirtIO-FS service is running in `services.msc`
- Ensure WinFsp is installed
- Check Device Manager for any unrecognized devices

### Clipboard not working
- Verify SPICE Guest Tools are installed
- Check that the SPICE agent service is running in `services.msc`
- In virt-manager: ensure display type is **Spice** (not VNC)

### Display not auto-resizing
- SPICE Guest Tools must be installed
- QXL driver must be active (Device Manager > Display adapters > QXL)
- Try: View > Scale Display > Auto resize VM with window

### Slow disk I/O
- Ensure disk bus is VirtIO (not SATA/IDE)
- Use cache mode "none" and IO mode "native" for best performance
