# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2021-2024 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie

include ../../lib/common.mk

prefix = build/host
imgdir = $(prefix)/img

VMM = cloud-hypervisor

HOST_BUILD_FILES = \
	$(imgdir)/appvm/blk/root.img \
	$(imgdir)/appvm/vmlinux

all: $(HOST_BUILD_FILES)
.PHONY: all

$(imgdir)/appvm/vmlinux: $(KERNEL)
	mkdir -p $$(dirname $@)
	cp $(KERNEL) $@

$(imgdir)/appvm/blk/root.img: ../../scripts/make-gpt.sh ../../scripts/sfdisk-field.awk build/rootfs.erofs
	mkdir -p $$(dirname $@)
	../../scripts/make-gpt.sh $@.tmp \
	    build/rootfs.erofs:4f68bce3-e8cd-4db1-96e7-fbcaf984b709:5460386f-2203-4911-8694-91400125c604:root
	mv $@.tmp $@

VM_FILES = \
	etc/dbus-1/session.conf \
	etc/fstab \
	etc/init \
	etc/mdev.conf \
	etc/mdev/iface \
	etc/mdev/listen \
	etc/mdev/virtiofs \
	etc/mdev/wait \
	etc/passwd \
	etc/resolv.conf \
	etc/s6-linux-init/env/DBUS_SESSION_BUS_ADDRESS \
	etc/s6-linux-init/env/NIX_XDG_DESKTOP_PORTAL_DIR \
	etc/s6-linux-init/scripts/rc.init \
	etc/xdg/xdg-desktop-portal/portals.conf
VM_DIRS = dev run proc sys \
	etc/s6-linux-init/env \
	etc/s6-linux-init/run-image/ext \
	etc/s6-linux-init/run-image/service

# These are separate because they need to be included, but putting
# them as make dependencies would confuse make.
VM_LINKS = bin etc/ssl/certs/ca-certificates.crt

VM_BUILD_FILES = build/etc/s6-rc

build/empty:
	mkdir -p $@

build/rootfs.erofs: ../../scripts/make-erofs.sh $(VM_FILES) $(VM_BUILD_FILES) build/empty
	( \
	    printf '%s\n' $$PACKAGES ;\
	    for file in $(VM_FILES) $(VM_LINKS); do printf '%s\n%s\n' $$file $$file; done ;\
	    for file in $(VM_BUILD_FILES); do printf '%s\n%s\n' $$file $${file#build/}; done ;\
	    printf 'build/empty\n%s\n' $(VM_DIRS) ;\
	) | ../../scripts/make-erofs.sh $@

VM_S6_RC_FILES = \
	etc/s6-rc/app/dependencies.d/dbus \
	etc/s6-rc/app/run \
	etc/s6-rc/app/type \
	etc/s6-rc/dbus/notification-fd \
	etc/s6-rc/dbus/run \
	etc/s6-rc/dbus/type \
	etc/s6-rc/mdevd-coldplug/dependencies \
	etc/s6-rc/mdevd-coldplug/type \
	etc/s6-rc/mdevd-coldplug/up \
	etc/s6-rc/mdevd/notification-fd \
	etc/s6-rc/mdevd/run \
	etc/s6-rc/mdevd/type \
	etc/s6-rc/ok-all/contents \
	etc/s6-rc/ok-all/type

build/etc/s6-rc: $(VM_S6_RC_FILES)
	mkdir -p $$(dirname $@)
	rm -rf $@

	dir=$$(mktemp -d) && \
	    tar -c $(VM_S6_RC_FILES) | tar -C $$dir -x --strip-components 2 && \
	    s6-rc-compile $@ $$dir; \
	    exit=$$?; rm -r $$dir; exit $$exit

debug:
	$(GDB) -q \
	    -ex 'set substitute-path .. $(LINUX_SRC)' \
	    -ex 'target remote build/gdb.sock' \
	    $(VMLINUX)
.PHONY: debug

start-vhost-user-gpu:
	rm -f build/vhost-user-gpu.sock
	$(CROSVM_DEVICE_GPU) \
	    --socket build/vhost-user-gpu.sock \
	    --wayland-sock "$$XDG_RUNTIME_DIR/$$WAYLAND_DISPLAY" \
	    --params '{"context-types":"cross-domain"}' &
	while ! [ -S build/vhost-user-gpu.sock ] && sleep .1; do :; done
.PHONY: start-vhost-user-gpu

start-virtiofsd:
	mkdir -p build
	$(S6_IPCSERVER_SOCKETBINDER) -B build/virtiofsd.sock \
	    $(BACKGROUND) $(VIRTIOFSD) --fd 0 --shared-dir . ""
.PHONY: start-virtiofsd

run-qemu: $(imgdir)/appvm/blk/root.img start-virtiofsd
	@../../scripts/run-qemu.sh -m 256 -cpu host -kernel $(KERNEL) -vga none \
	    -drive file=$(imgdir)/appvm/blk/root.img,if=virtio,format=raw,readonly=on \
	    -drive file=$(RUN_IMG),if=virtio,format=raw,readonly=on \
	    -append "root=PARTLABEL=root nokaslr" \
	    -gdb unix:build/gdb.sock,server,nowait \
	    -netdev user,id=net0 \
	    -device virtio-net,netdev=net0,mac=0A:B3:EC:00:00:00 \
	    -chardev socket,id=virtiofsd,path=build/virtiofsd.sock \
	    -device vhost-user-fs-pci,chardev=virtiofsd,tag=virtiofs0 \
	    -device virtio-gpu-rutabaga-pci,cross-domain=on,hostmem=8G \
	    -object memory-backend-memfd,id=mem,size=256M,share=on \
	    -numa node,memdev=mem \
	    -device vhost-vsock-pci,guest-cid=3 \
	    -chardev vc,id=virtiocon0 \
	    -device virtio-serial-pci \
	    -device virtconsole,chardev=virtiocon0
.PHONY: run-qemu

run-cloud-hypervisor: $(imgdir)/appvm/blk/root.img start-vhost-user-gpu start-virtiofsd
	rm -f build/vmm.sock build/vsock.sock
	@../../scripts/with-taps.elb ../../scripts/run-cloud-hypervisor.sh \
	    --api-socket path=build/vmm.sock \
	    --memory size=256M,shared=on \
	    --disk path=$(imgdir)/appvm/blk/root.img,readonly=on \
	           path=$(RUN_IMG),readonly=on \
	    --fs tag=virtiofs0,socket=build/virtiofsd.sock \
	    --gpu socket=build/vhost-user-gpu.sock \
	    --vsock cid=3,socket=build/vsock.sock \
	    --net tap=tap0 \
	    --kernel $(KERNEL) \
	    --cmdline "root=PARTLABEL=root" \
	    --console tty \
	    --serial file=build/serial.log
.PHONY: run-cloud-hypervisor

run-crosvm: $(imgdir)/appvm/blk/root.img start-vhost-user-gpu start-virtiofsd
	../../scripts/with-taps.elb $(CROSVM_RUN) \
	    --disk $(imgdir)/appvm/blk/root.img \
	    --disk $(RUN_IMG) \
	    -p "console=ttyS0 root=PARTLABEL=root" \
	    --net tap-name=tap0 \
	    --vhost-user-fs build/virtiofsd.sock:virtiofs0 \
	    --vhost-user-gpu build/vhost-user-gpu.sock \
	    --vsock cid=3 \
	    --serial type=file,hardware=serial,path=build/serial.log \
	    --serial type=stdout,hardware=virtio-console,stdin=true \
	    $(KERNEL)
.PHONY: run-crosvm

run: run-$(VMM)
.PHONY: run

clean:
	rm -rf build
.PHONY: clean
