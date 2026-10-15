This is for of https://github.com/usb4java/libusb4java
Statically-linked JNI wrapper for libusb used by usb4java.

```java

<dependency>
    <groupId>org.usb4jav</groupId>
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
    <version>1.0.30</version>
</dependency>
```
