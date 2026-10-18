Fork of the https://github.com/usb4java/libusb4java

Statically-linked JNI wrapper for libusb used by usb4java

### Usage
```java
<dependencies>
        <dependency>
            <groupId>org.usb4java</groupId>
            <artifactId>usb4java</artifactId>
            <version>1.3.0</version>
            <exclusions>
                <exclusion>
                    <groupId>org.usb4java</groupId>
                    <artifactId>libusb4java</artifactId>
                </exclusion>
            </exclusions>
            <scope>compile</scope>
        </dependency>

        <dependency>
            <groupId>ru.redrise</groupId>
            <artifactId>libusb4java</artifactId>
            <classifier>linux-x86-64</classifier>
            <version>1.0.30</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>ru.redrise</groupId>
            <artifactId>libusb4java</artifactId>
            <classifier>win32-x86-64</classifier>
            <version>1.0.30</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>ru.redrise</groupId>
            <artifactId>libusb4java</artifactId>
            <classifier>linux-arm</classifier>
            <version>1.0.30</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>ru.redrise</groupId>
            <artifactId>libusb4java</artifactId>
            <classifier>linux-aarch64</classifier>
            <version>1.0.30</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>ru.redrise</groupId>
            <artifactId>libusb4java</artifactId>
            <classifier>darwin-x86-64</classifier>
            <version>1.0.30</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>ru.redrise</groupId>
            <artifactId>libusb4java</artifactId>
            <classifier>darwin-aarch64</classifier>
            <version>1.0.30</version>
            <scope>compile</scope>
        </dependency>
</dependencies>
```

### Build

Jars are built by GitHub Actions (`.github/workflows/ci.yml`) for the
following classifiers:

| classifier      | target                                   |
| --------------- | ---------------------------------------- |
| `linux-x86-64`  | Linux amd64                              |
| `linux-aarch64` | Linux arm64 (64-bit ARM, e.g. Pi 4/5 64-bit OS) |
| `linux-arm`     | Linux armv7 (32-bit ARM, Raspberry Pi 32-bit OS) |
| `win32-x86-64`  | Windows amd64                            |
| `darwin-x86-64` | macOS x64                                |
| `darwin-aarch64`| macOS arm64                              |

The `linux-arm` jar is a genuine 32-bit armv7 build: it is cross-compiled
inside a native amd64 `debian:bookworm` docker container using
`gcc-arm-linux-gnueabihf` (see `ci/build_arm.sh`). The container's glibc
2.36 matches Raspberry Pi OS (Debian 12 based), so the native library loads
on 32-bit Pi OS. eudev is built from source and statically linked, keeping
libusb hotplug support.
