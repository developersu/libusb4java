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
